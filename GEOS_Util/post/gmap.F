#include "unused_dummy.H"
c****6***0*********0*********0*********0*********0*********0**********72
      subroutine gmap(im, jm, nq,  akap,
     &         km,  pk3d_m,  pe3d_m, u_m,  v_m,  pt_m,  q_m,
     &         kn,  pk3d_n,  pe3d_n, u_n,  v_n,  pt_n,  q_n  )
c****6***0*********0*********0*********0*********0*********0**********72

      implicit none

      integer im, jm
      integer km, kn, nq

C Input:
C original data km-level

      real      u_m(im,jm,km)
      real      v_m(im,jm,km)
      real     pt_m(im,jm,km)
      real      q_m(im,jm,km,nq)
      real   pk3d_m(im,jm,km+1)
      real   pe3d_m(im,jm,km+1)

      real   pk3d_n(im,jm,kn+1)
      real   pe3d_n(im,jm,kn+1)

C Output:
C New data (kn-level)
      real      u_n(im,jm,kn)
      real      v_n(im,jm,kn)
      real     pt_n(im,jm,kn)
      real      q_n(im,jm,kn,nq)

c local (private)
      integer i, j, k, n

      real pe1(im,km+1) ,pe2(im,kn+1)
      real pk1(im,km+1) ,pk2(im,kn+1)
      real dp1(im,km)   ,dp2(im,kn)
      real  u1(im,km)   , u2(im,kn)
      real  v1(im,km)   , v2(im,kn)
      real  t1(im,km)   , t2(im,kn)
      real  q1(im,km,nq), q2(im,kn,nq)

      real akap
      real undef
      real big
      parameter ( undef = 1.e15 )
      parameter (   big = 1.e10 )

      _UNUSED_DUMMY(akap)

#if   (openmp)
!$omp  parallel do
!$omp& default (shared)
!$omp& private (i,j,k,pe1,pe2,pk1,pk2,dp1,dp2,u1,v1,t1,q1)
!$omp& private (u2,v2,t2,q2)
#endif
      do 2000 j=1,jm

c Copy original data to local 2D arrays.

      do k=1,km+1
      do i=1,im
      pe1(i,k) = pe3d_m(i,j,k)
      pk1(i,k) = pk3d_m(i,j,k)
      enddo
      enddo

      do k=1,kn+1
      do i=1,im
      pe2(i,k) = pe3d_n(i,j,k)
      pk2(i,k) = pk3d_n(i,j,k)
      enddo
      enddo

      do k=1,km
      do i=1,im
      dp1(i,k) =  pk1(i,k+1)-pk1(i,k)
       u1(i,k) =  u_m(i,j,k)
       v1(i,k) =  v_m(i,j,k)
       t1(i,k) = pt_m(i,j,k)
      enddo
      enddo
      do n=1,nq
      do k=1,km
      do i=1,im
       q1(i,k,n) =  q_m(i,j,k,n)
      enddo
      enddo
      enddo

      do k=1,kn
      do i=1,im
      dp2(i,k) = pk2(i,k+1)-pk2(i,k)
      enddo
      enddo

c map pt
c ------
      call mappm ( km, pk1, dp1, t1, kn, pk2, dp2, t2, im, 1, 7 )

      do k=1,km
      do i=1,im
      dp1(i,k) = pe1(i,k+1)-pe1(i,k)
      enddo
      enddo

      do k=1,kn
      do i=1,im
      dp2(i,k) = pe2(i,k+1)-pe2(i,k)
      enddo
      enddo

c map u,v,q,oz
c ------------
      do n=1,nq
      call mappm ( km, pe1, dp1, q1(1,1,n), kn, pe2, dp2, q2(1,1,n), im,  0, 7 )
      enddo
      call mappm ( km, pe1, dp1, u1, kn, pe2, dp2, u2, im, -1, 7 )
      call mappm ( km, pe1, dp1, v1, kn, pe2, dp2, v2, im, -1, 7 )

      do k=1,kn
      do i=1,im
        u_n(i,j,k) = u2(i,k)
        v_n(i,j,k) = v2(i,k)
       pt_n(i,j,k) = t2(i,k)
      enddo
      enddo
      do n=1,nq
      do k=1,kn
      do i=1,im
        q_n(i,j,k,n) = q2(i,k,n)
      enddo
      enddo
      enddo

2000  continue

      return
      end


C****6***0*********0*********0*********0*********0*********0**********72
      subroutine mappm(km, pe1, dp1, q1, kn, pe2, dp2, q2, im, iv, kord)
C****6***0*********0*********0*********0*********0*********0**********72
C IV = 0: constituents
C IV = 1: potential temp
C IV =-1: winds
C
C Mass flux preserving mapping: q1(im,km) -> q2(im,kn)
C
C pe1: pressure at layer edges (from model top to bottom surface)
C      in the original vertical coordinate
C pe2: pressure at layer edges (from model top to bottom surface)
C      in the new vertical coordinate

      parameter (kmax = 200)
      parameter (R3 = 1./3., R23 = 2./3.)

      real dp1(im,km),   dp2(im,kn),
     &      q1(im,km),    q2(im,kn),
     &     pe1(im,km+1), pe2(im,kn+1)
      integer kord

C local work arrays
      real a4(4,im,km)

      _UNUSED_DUMMY(dp2)

      do k=1,km
         do i=1,im
            a4(1,i,k) = q1(i,k)
         enddo
      enddo

      call ppm2m(a4, dp1, im, km, iv, kord)

C Lowest layer: constant distribution
      do i=1, im
         a4(2,i,km) = q1(i,km)
         a4(3,i,km) = q1(i,km)
         a4(4,i,km) = 0.
      enddo

      do 5555 i=1,im
         k0 = 1
      do 555 k=1,kn

         if(pe2(i,k+1) .le. pe1(i,1)) then
! Entire grid above old ptop
            q2(i,k) = a4(2,i,1)
         elseif(pe2(i,k) .ge. pe1(i,km+1)) then
! Entire grid below old ps
            q2(i,k) = a4(3,i,km)
         elseif(pe2(i,k  ) .lt. pe1(i,1) .and.
     &          pe2(i,k+1) .gt. pe1(i,1))  then
! Part of the grid above ptop
            q2(i,k) = a4(1,i,1)
         else

         do 45 L=k0,km
! locate the top edge at pe2(i,k)
         if( pe2(i,k) .ge. pe1(i,L) .and.
     &       pe2(i,k) .le. pe1(i,L+1)    ) then
             k0 = L
             PL = (pe2(i,k)-pe1(i,L)) / dp1(i,L)
             if(pe2(i,k+1) .le. pe1(i,L+1)) then

! entire new grid is within the original grid
               PR = (pe2(i,k+1)-pe1(i,L)) / dp1(i,L)
               TT = R3*(PR*(PR+PL)+PL**2)
               q2(i,k) = a4(2,i,L) + 0.5*(a4(4,i,L)+a4(3,i,L)
     &                 - a4(2,i,L))*(PR+PL) - a4(4,i,L)*TT
              goto 555
             else
! Fractional area...
              delp = pe1(i,L+1) - pe2(i,k)
              TT   = R3*(1.+PL*(1.+PL))
              qsum = delp*(a4(2,i,L)+0.5*(a4(4,i,L)+
     &               a4(3,i,L)-a4(2,i,L))*(1.+PL)-a4(4,i,L)*TT)
              dpsum = delp
              k1 = L + 1
             goto 111
             endif
         endif
45       continue

111      continue
         do 55 L=k1,km
         if( pe2(i,k+1) .gt. pe1(i,L+1) ) then

! Whole layer..

            qsum  =  qsum + dp1(i,L)*q1(i,L)
            dpsum = dpsum + dp1(i,L)
         else
           delp = pe2(i,k+1)-pe1(i,L)
           esl  = delp / dp1(i,L)
           qsum = qsum + delp * (a4(2,i,L)+0.5*esl*
     &           (a4(3,i,L)-a4(2,i,L)+a4(4,i,L)*(1.-r23*esl)) )
          dpsum = dpsum + delp
           k0 = L
           goto 123
         endif
55       continue
        delp = pe2(i,k+1) - pe1(i,km+1)
        if(delp .gt. 0.) then
! Extended below old ps
           qsum = qsum + delp * a4(3,i,km)
          dpsum = dpsum + delp
        endif
123     q2(i,k) = qsum / dpsum
      endif
555   continue
5555  continue

      return
      end

c****6***0*********0*********0*********0*********0*********0**********72
      subroutine ppm2m(a4,delp,im,km,iv,kord)
c****6***0*********0*********0*********0*********0*********0**********72
c iv = 0: positive definite scalars
c iv = 1: others
c iv =-1: winds

      implicit none

      integer im, km, lmt, iv
      integer kord
      integer i, k, km1
      real a4(4,im,km), delp(im,km)

c local arrays.
      real dc(im,km),delq(im,km)
      real h2(im,km)
      real a1, a2, c1, c2, c3, d1, d2
      real qmax, qmin, cmax, cmin
      real qm, dq, tmp

C Local scalars:
      real qmp
      real lac

      km1 = km - 1

      do 500 k=2,km
      do 500 i=1,im
      delq(i,k-1) = a4(1,i,k) - a4(1,i,k-1)
500   a4(4,i,k  ) = delp(i,k-1) + delp(i,k)

      do 1220 k=2,km1
      do 1220 i=1,im
      c1 = (delp(i,k-1)+0.5*delp(i,k))/a4(4,i,k+1)
      c2 = (delp(i,k+1)+0.5*delp(i,k))/a4(4,i,k)
      tmp = delp(i,k)*(c1*delq(i,k) + c2*delq(i,k-1)) /
     &                              (a4(4,i,k)+delp(i,k+1))
      qmax = max(a4(1,i,k-1),a4(1,i,k),a4(1,i,k+1)) - a4(1,i,k)
      qmin = a4(1,i,k) - min(a4(1,i,k-1),a4(1,i,k),a4(1,i,k+1))
      dc(i,k) = sign(min(abs(tmp),qmax,qmin), tmp)
1220  continue

c****6***0*********0*********0*********0*********0*********0**********72
c 4th order interpolation of the provisional cell edge value
c****6***0*********0*********0*********0*********0*********0**********72

      do 12 k=3,km1
      do 12 i=1,im
      c1 = delq(i,k-1)*delp(i,k-1) / a4(4,i,k)
      a1 = a4(4,i,k-1) / (a4(4,i,k) + delp(i,k-1))
      a2 = a4(4,i,k+1) / (a4(4,i,k) + delp(i,k))
      a4(2,i,k) = a4(1,i,k-1) + c1 + 2./(a4(4,i,k-1)+a4(4,i,k+1)) *
     &          ( delp(i,k)*(c1*(a1 - a2)+a2*dc(i,k-1)) -
     &                          delp(i,k-1)*a1*dc(i,k  ) )
12    continue

C Area preserving cubic with 2nd deriv. = 0 at the boundaries
C Top
      do i=1,im
      d1 = delp(i,1)
      d2 = delp(i,2)
      qm = (d2*a4(1,i,1)+d1*a4(1,i,2)) / (d1+d2)
      dq = 2.*(a4(1,i,2)-a4(1,i,1)) / (d1+d2)
      c1 = 4.*(a4(2,i,3)-qm-d2*dq) / ( d2*(2.*d2*d2+d1*(d2+3.*d1)) )
      c3 = dq - 0.5*c1*(d2*(5.*d1+d2)-3.*d1**2)
      a4(2,i,2) = qm - 0.25*c1*d1*d2*(d2+3.*d1)
      a4(2,i,1) = d1*(2.*c1*d1**2-c3) + a4(2,i,2)
      dc(i,1) =  a4(1,i,1) - a4(2,i,1)
C No over- and undershoot condition
      cmax = max(a4(1,i,1), a4(1,i,2))
      cmin = min(a4(1,i,1), a4(1,i,2))
      a4(2,i,2) = max(cmin,a4(2,i,2))
      a4(2,i,2) = min(cmax,a4(2,i,2))
      enddo

      if(iv == 0) then
         do i=1,im
            a4(2,i,1) = max(0.,a4(2,i,1))
            a4(2,i,2) = max(0.,a4(2,i,2))
         enddo
      elseif(iv == -1) then
         do i=1,im
            if( a4(2,i,1)*a4(1,i,1) <= 0. ) a4(2,i,1) = 0.
         enddo
      endif

c****6***0*********0*********0*********0*********0*********0**********72

c Bottom
c Area preserving cubic with 2nd deriv. = 0 at the surface
      do 15 i=1,im
      d1 = delp(i,km)
      d2 = delp(i,km1)
      qm = (d2*a4(1,i,km)+d1*a4(1,i,km1)) / (d1+d2)
      dq = 2.*(a4(1,i,km1)-a4(1,i,km)) / (d1+d2)
      c1 = (a4(2,i,km1)-qm-d2*dq) / (d2*(2.*d2*d2+d1*(d2+3.*d1)))
      c3 = dq - 2.0*c1*(d2*(5.*d1+d2)-3.*d1**2)
      a4(2,i,km) = qm - c1*d1*d2*(d2+3.*d1)
      a4(3,i,km) = d1*(8.*c1*d1**2-c3) + a4(2,i,km)
      dc(i,km) = a4(3,i,km) -  a4(1,i,km)
c****6***0*********0*********0*********0*********0*********0**********72
c No over- and undershoot condition
      cmax = max(a4(1,i,km), a4(1,i,km1))
      cmin = min(a4(1,i,km), a4(1,i,km1))
      a4(2,i,km) = max(cmin,a4(2,i,km))
      a4(2,i,km) = min(cmax,a4(2,i,km))
c****6***0*********0*********0*********0*********0*********0**********72
15    continue

      if(iv .eq. 0) then
      do i=1,im
         a4(2,i,km) = max(0.,a4(2,i,km))
         a4(3,i,km) = max(0.,a4(3,i,km))
      enddo
      endif

      do 20 k=1,km1
      do 20 i=1,im
      a4(3,i,k) = a4(2,i,k+1)
20    continue
c
c f(s) = AL + s*[(AR-AL) + A6*(1-s)]         ( 0 <= s  <= 1 )
c

c Top 2 and bottom 2 layers always use monotonic mapping

      do k=1,2
         do i=1,im
            a4(4,i,k) = 3.*(2.*a4(1,i,k) - (a4(2,i,k)+a4(3,i,k)))
         enddo
         call kmppm(dc(1,k),a4(1,1,k),im, 0)
      enddo

      if(kord == 7) then
c****6***0*********0*********0*********0*********0*********0**********72
C Huynh's 2nd constraint
c****6***0*********0*********0*********0*********0*********0**********72
      do k=2, km1
         do i=1,im
            h2(i,k) = delq(i,k) - delq(i,k-1)
         enddo
      enddo

      do 4000 k=3, km-2
      do 3000 i=1, im
C Right edges
         qmp   = a4(1,i,k)                 + 2.0*delq(i,k-1)
         lac   = a4(1,i,k) + 1.5*h2(i,k-1) + 0.5*delq(i,k-1)
         qmin  = min(a4(1,i,k), qmp, lac)
         qmax  = max(a4(1,i,k), qmp, lac)
         a4(3,i,k) = min(max(a4(3,i,k), qmin), qmax)
C Left  edges
         qmp   = a4(1,i,k)                 - 2.0*delq(i,k)
         lac   = a4(1,i,k) + 1.5*h2(i,k+1) - 0.5*delq(i,k)
         qmin  = min(a4(1,i,k), qmp, lac)
         qmax  = max(a4(1,i,k), qmp, lac)
         a4(2,i,k) = min(max(a4(2,i,k), qmin), qmax)
C Recompute A6
         a4(4,i,k) = 3.*(2.*a4(1,i,k) - (a4(2,i,k)+a4(3,i,k)))
3000  continue
! Additional constraint to prevent negatives
         if (iv == 0) then
             call kmppm(dc(1,k),a4(1,1,k),im, 2)
         endif
4000  continue

      else

         lmt = kord - 3
         lmt = max(0, lmt)
         if (iv .eq. 0) lmt = min(2, lmt)

      do k=3, km-2
         do i=1,im
            a4(4,i,k) = 3.*(2.*a4(1,i,k) - (a4(2,i,k)+a4(3,i,k)))
         enddo
         call kmppm(dc(1,k),a4(1,1,k),im, lmt)
      enddo
      endif

      do 5000 k=km1,km
         do i=1,im
         a4(4,i,k) = 3.*(2.*a4(1,i,k) - (a4(2,i,k)+a4(3,i,k)))
         enddo
         call kmppm(dc(1,k),a4(1,1,k),im, 0)
5000  continue

      return
      end

c****6***0*********0*********0*********0*********0*********0**********72
      subroutine kmppm(dm, a4, km, lmt)
c****6***0*********0*********0*********0*********0*********0**********72
      implicit none

      real r12
      parameter (r12 = 1./12.)

      integer km, lmt
      integer i
      real a4(4,km),dm(km)
      real da1, da2, a6da
      real fmin
      real qmp

      if (lmt .eq. 3) return
! Full constraint

      if(lmt .eq. 0) then
      do 100 i=1,km
      if(dm(i) .eq. 0.) then
         a4(2,i) = a4(1,i)
         a4(3,i) = a4(1,i)
         a4(4,i) = 0.
      else
         da1  = a4(3,i) - a4(2,i)
         da2  = da1**2
         a6da = a4(4,i)*da1
         if(a6da .lt. -da2) then
            a4(4,i) = 3.*(a4(2,i)-a4(1,i))
            a4(3,i) = a4(2,i) - a4(4,i)
         elseif(a6da .gt. da2) then
            a4(4,i) = 3.*(a4(3,i)-a4(1,i))
            a4(2,i) = a4(3,i) - a4(4,i)
         endif
      endif
100   continue
      elseif (lmt .eq. 2) then
c Positive definite

c Positive definite constraint
      do 250 i=1,km
      if(abs(a4(3,i)-a4(2,i)) .ge. -a4(4,i)) go to 250
      fmin = a4(1,i)+0.25*(a4(3,i)-a4(2,i))**2/a4(4,i)+a4(4,i)*r12
      if(fmin.ge.0.) go to 250
      if(a4(1,i).lt.a4(3,i) .and. a4(1,i).lt.a4(2,i)) then
            a4(3,i) = a4(1,i)
            a4(2,i) = a4(1,i)
            a4(4,i) = 0.
      elseif(a4(3,i) .gt. a4(2,i)) then
            a4(4,i) = 3.*(a4(2,i)-a4(1,i))
            a4(3,i) = a4(2,i) - a4(4,i)
      else
            a4(4,i) = 3.*(a4(3,i)-a4(1,i))
            a4(2,i) = a4(3,i) - a4(4,i)
      endif
250   continue

      elseif (lmt == 1) then

! Improved full monotonicity constraint (Lin)
! Note: no need to provide first guess of A6 <-- a4(4,i)

      do i=1, km
           qmp = 2.*dm(i)
         a4(2,i) = a4(1,i)-sign(min(abs(qmp),abs(a4(2,i)-a4(1,i))), qmp)
         a4(3,i) = a4(1,i)+sign(min(abs(qmp),abs(a4(3,i)-a4(1,i))), qmp)
         a4(4,i) = 3.*( 2.*a4(1,i) - (a4(2,i)+a4(3,i)) )
      enddo
      endif

      return
      end

