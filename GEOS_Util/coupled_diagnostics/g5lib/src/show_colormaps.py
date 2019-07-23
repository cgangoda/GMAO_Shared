import numpy as np
import matplotlib.pyplot as plt
from matplotlib import cm
from mpl_toolkits.basemap import cm as cmb
a=np.outer(np.arange(0,1,0.01),np.ones(10))
plt.figure(figsize=(10,7))
plt.subplots_adjust(top=0.8,bottom=0.05,left=0.01,right=0.99)
maps=[m for m in cm.datad.keys() if not m.endswith("_r")]
maps.sort()
l=len(maps)+1
i=1
for m in maps:
    plt.subplot(1,l,i)
    plt.axis("off")
    plt.imshow(a,aspect='auto',cmap=cm.__dict__[m],origin="lower")
    plt.title(m,rotation=90,fontsize=10,backgroundcolor='white',va='bottom')
    i=i+1
plt.show()

plt.figure(figsize=(10,7))
plt.subplots_adjust(top=0.8,bottom=0.05,left=0.01,right=0.99)
maps=[m for m in cmb.datad.keys() if not m.endswith("_r")]
maps.sort()
l=len(maps)+1
i=1
for m in maps:
    plt.subplot(1,l,i)
    plt.axis("off")
    plt.imshow(a,aspect='auto',cmap=cmb.__dict__[m],origin="lower")
    plt.title(m,rotation=90,fontsize=10,backgroundcolor='white',va='bottom')
    i=i+1
plt.show()
