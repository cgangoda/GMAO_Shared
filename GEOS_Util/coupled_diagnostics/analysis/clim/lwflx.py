#!/usr/bin/env python

import matplotlib
matplotlib.use('Agg')

import os, sys
from importlib import import_module
import scipy as sp
import matplotlib.pyplot as pl
from matplotlib import colors
from mpl_toolkits.basemap.cm import sstanom
from matplotlib.cm import jet
import g5lib.plotters as ptrs
from  g5lib import cmaps as g5cmaps
from g5lib import g5dset

varname='LWFLX'

# Read data
exp=g5dset.read_exp(sys.argv[1])
exp.ctl=g5dset.Ctl(exp,'geosgcm_ocn2d')

exp.clim=exp.ctl(varname,dates=exp.dates,levs=(0,),lats=(-64.,64.)).clim(12)
exp.clim.shiftgrid(30.);

ind=[0,1,11]; exp.djf=exp.clim.subset(tind=ind).mean(0); exp.djf.name+=', DJF'
ind=[5,6,7]; exp.jja=exp.clim.subset(tind=ind).mean(0); exp.jja.name+=', JJA'
exp.am=exp.clim.mean(0); exp.am.name+=', Annual Mean'

# Read experiment to compare
exp1=g5dset.read_exp(exp.cmpexp)
exp1.ctl=g5dset.Ctl(exp1,'geosgcm_ocn2d')

exp1.clim=exp1.ctl(varname,dates=exp1.dates,levs=(0,),lats=(-64.,64.)).clim(12)
exp1.clim.shiftgrid(30.);
if exp1.clim.dims[2:]!=exp.clim.dims[2:]:
    exp1.clim.regrid(exp.clim.grid, newmask=exp.clim.data.mask)

ind=[0,1,11]; exp1.djf=exp1.clim.subset(tind=ind).mean(0); exp1.djf.name+=' DJF'
ind=[5,6,7]; exp1.jja=exp1.clim.subset(tind=ind).mean(0); exp1.jja.name+=' JJA'
exp1.am=exp1.clim.mean(0); exp1.am.name+=' Annual Mean'

# Read validation data set
obs=import_module('OAFlux')

obs.clim=obs.ctllwsw('nlwrs').clim(12)
obs.clim.data=sp.roll(obs.clim.data,6,0)
obs.clim.time=sp.roll(obs.clim.time,6,0)
obs.clim.shiftgrid(30.);

# Regrid to model grid
obs.clim.regrid(exp.clim.grid, newmask=exp.clim.data.mask)

ind=[0,1,11]; obs.djf=obs.clim.subset(tind=ind).mean(0)
obs.djf.name=obs.ctllhsh.name+' '+obs.djf.name+' DJF'
ind=[5,6,7]; obs.jja=obs.clim.subset(tind=ind).mean(0)
obs.jja.name=obs.ctllhsh.name+' '+obs.jja.name+' JJA'
obs.am=obs.clim.mean(0); obs.am.name=obs.ctllhsh.name+' '+obs.am.name+' Annual Mean'

# Plots

def plot_field(field, fig, clevs, cmap, fill_range=None):
    pl.figure(fig)
    pl.clf()
    n=colors.Normalize()
    n.autoscale(clevs)
    if fill_range is not None:
        m=g5cmaps.FilledCmap(cmap, fill_range=n(fill_range))
    else: 
        m=cmap
    p=ptrs.GeoPlotter(copts=dict(levels=clevs, cmap=m, norm=n))
    p(field)
    p.method=p.map.contour
    p.copts=dict(levels=clevs[0::2], colors='black')
    p(field,stat=True)
    pl.show()
    
clevs1=sp.arange(-100,0.1,10.0); clevs2=sp.arange(-50.,51.0,10.)    
frange=(-1,1)
path=exp.plot_path
try:
    os.makedirs(path)
except OSError:
    pass

#DJF
plot_field(exp.djf,1,clevs1,jet)
pl.savefig(path+'/lwflx_djf.png')

dif=exp.djf.subset(); dif.data-=obs.djf.data
dif.name=exp.ctl.name+'-'+obs.ctllhsh.name+' DJF'
plot_field(dif,2,clevs2,sstanom,frange)
pl.savefig(path+'/lwflx-obs_djf.png')

dif=exp.djf.subset(); dif.data-=exp1.djf.data
dif.name=exp.ctl.name+'-'+exp1.ctl.name+' DJF'
plot_field(dif,3,clevs2,sstanom,frange)
pl.savefig(path+'/lwflx-dif_djf.png')

#JJA
plot_field(exp.jja,1,clevs1,jet)
pl.savefig(path+'/lwflx_jja.png')

dif=exp.jja.subset(); dif.data-=obs.jja.data
dif.name=exp.ctl.name+'-'+obs.ctllhsh.name+' JJA'
plot_field(dif,2,clevs2,sstanom,frange)
pl.savefig(path+'/lwflx-obs_jja.png')

dif=exp.jja.subset(); dif.data-=exp1.jja.data
dif.name=exp.ctl.name+'-'+exp1.ctl.name+' JJA'
plot_field(dif,3,clevs2,sstanom,frange)
pl.savefig(path+'/lwflx-dif_jja.png')

#AM
plot_field(exp.am,1,clevs1,jet)
pl.savefig(path+'/lwflx_am.png')

dif=exp.am.subset(); dif.data-=obs.am.data
dif.name=exp.ctl.name+'-'+obs.ctllhsh.name+' Annual Mean'
plot_field(dif,2,clevs2,sstanom,frange)
pl.savefig(path+'/lwflx-obs_am.png')

dif=exp.am.subset(); dif.data-=exp1.am.data
dif.name=exp.ctl.name+'-'+exp1.ctl.name+' Annual Mean'
plot_field(dif,3,clevs2,sstanom,frange)
pl.savefig(path+'/lwflx-dif_am.png')

