
      subroutine oneline (imode)                                    
c******************************************************************************
c     This routine computes a single line profile                       
c******************************************************************************

      implicit real*8 (a-h,o-z)
      include 'Atmos.com'
      include 'Linex.com'
      include 'Dummy.com'
      real*8 dinteg(200)
      data waveold /0.0/                                   


c*****set an arbitrary maximum # of wavelength points to compute 
c     the line profile
      maxsteps = 75


c*****get started; calculate the step size
      if (imode .eq. 0) gf1(ncurve) = gf(lim1)                          
      dellam(1) = 0.                                                    
      if (wavestep .eq. 0.) then
         st1 = wave1(lim1)*dopp(lim1,jtau5)/2.997929e10/5.
         st1 = dfloat(ifix(10000.*sngl(st1)))/10000.
      else
         st1 = wavestep
      endif


c*****calculate the continuous opacity at line wavelength               
      wave = wave1(lim1)                                                
      if (abs(wave-waveold) .gt. 30.) then
         waveold = wave
         call opacit(2,wave)     
         if (imode.ne.2 .and. modprintopt.ge.2) 
     .      write(nf1out,1002) wave,(kaplam(i),i=1,ntau)


c*****calculate continuum intensity/flux                                
         call cdcalc(1)
         first = 0.4343*cd(1)
         flux = rinteg(xref,cd,dummy1,ntau,first)
         if (imode .ne. 2) then
            if (iunits .eq. 1) then
               write (nf1out,1003) 1.d-4*wave,flux
            else
               write (nf1out,1004) wave,flux
            endif
         endif
      endif


c*****recheck the wavelength step size
      if (wavestep .eq. 0.) then
140      wave = wave1(lim1)
         call taukap
         call cdcalc(2)
         first = 0.4343*cd(1)
         d(1) = rinteg(xref,cd,dummy1,ntau,first)
         wave = wave + 5.*st1
         call taukap
         call cdcalc(2)
         first = 0.4343*cd(1)
         d(2) = rinteg(xref,cd,dummy1,ntau,first)       
         if (d(2)/d(1) .lt. 0.7) then
            st1 = st1/1.5
            st1 = dfloat(ifix(10000.*sngl(st1)))/10000.
            go to 140
         elseif (d(2)/d(1) .gt. 0.85) then
            st1 = st1*2.2
            st1 = dfloat(ifix(10000.*sngl(st1)))/10000.                 
            go to 140
         endif
      endif
      wave = wave1(lim1)                                                
      if (imode .ne. 2) write (nf1out,1001) lim1,st1


c*****calculate wavelength dependent line quantities, and the line depth
c     until the depth is very small in the line wing
      do n=1,maxsteps
         call taukap
         call cdcalc(2)
         first = 0.4343*cd(1)
         d(n) = rinteg(xref,cd,dummy1,ntau,first)       
         if (linprintopt.ge.3 .and. n.eq.1 .and. imode.eq.2) then
            do i=1,ntau
               dummy1(i) = xref(i)*cd(i)
            enddo
            first = 0.
            cdmean = rinteg(xref,dummy1,dummy2,ntau,first)/
     .               rinteg(xref,cd,dummy2,ntau,first)
            do i=1,ntau
               if (cdmean .lt. cd(i)) go to 150
            enddo
150         write (nf1out,1005) lim1, cdmean, i, xref(i)
            do i=1,ntau
               if (taunu(i)+taulam(i) .ge. 1.) go to 155
            enddo
155         write (nf1out,1006) lim1, i, dlog10(tauref(i)),
     .                          dlog10(taulam(i)), dlog10(taunu(i))
         endif
         if (d(n)/d(1) .lt. 0.0075) then
            ndepths = n
            go to 160
         endif
         dellam(n+1) = dellam(n) + st1
         wave = wave1(lim1) + dellam(n+1)
      enddo                                                             
      if (d(n).gt.0.001 .and. imode.ne.2) write (nf1out,1007)
      ndepths = maxsteps 


c*****finish the calculation                                            
160   if (imode .ne. 2) write (nf1out,1008) (d(j),j=1,ndepths)
      do n=2,ndepths
         d(ndepths+n-1) = d(n)
      enddo
      d(ndepths) = d(1)
      do n=2,ndepths
         d(n-1) = d(2*ndepths+1-n)
      enddo
      dellam(1) = -st1*(ndepths-1)
      ndep = 2*ndepths - 1
      do n=2,ndep
         dellam(n) = dellam(n-1) + st1
      enddo
      first = 2*dellam(ndep)*d(ndep)
      w(ncurve) = rinteg(dellam,d,dinteg,ndep,first) 
      if (imode .ne. 2) then
         ew = 1000.0*w(ncurve)
         gflog = dlog10(gf1(ncurve))
         rwlog = dlog10(w(ncurve)/wave1(lim1))
         write (nf1out,1009) wave1(lim1), ew, rwlog, gf1(ncurve), gflog
      endif
      return                                                            


c*****format statements
1001  format (/'LINE ', i5, ':', 10x, 'wavelength step size =',f7.4)
1002  format ('  kaplam from 1 to ntau at wavelength',f10.2/
     1        (6(1pd12.4)))
1003  format ('AT WAVELENGTH/FREQUENCY =',f11.7,
     .        '  CONTINUUM FLUX/INTENSITY =',1p,d12.5)
1004  format ('AT WAVELENGTH/FREQUENCY =',f11.3,
     .        '  CONTINUUM FLUX/INTENSITY =',1p,d12.5)
1005  format (/'LINE ', i5, ':',
     .        ' weighted mean line contribution function C_d =',
     .        f6.2/ '  which occurs near level ', i3,
     .        ' with log tauref = ', f6.2)
1006  format (/'LINE ', i5, ':',
     .        '  tau(total) is greater than 1 at level',i3/
     .        '  logs of tauref, taulam, taunu =', 3f6.2)
1007  format ('WARNING:  not enough points to specify the line?')
1008  format (10f7.3)
1009  format('lambda =',f12.3,5x,'E.W. =',f8.1,' mA.',5x,
     .       'log(R.W.) =',f6.2/'gf =',1pd10.3,5x,'log(gf) =',
     .       0pf7.2)

      end                                                               


