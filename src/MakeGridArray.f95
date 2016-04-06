subroutine MakeGridArray(d, cilm, lmax, lat, longitude, nmax, norm, &
                            csphase, dealloc)
!-------------------------------------------------------------------------------
!
!   This subroutine will determine the value at a given latitude and 
!   longitude corresponding to the given set of spherical harmonics.
!   Latitude and Longitude are assumed to be in DEGREES!
!
!   Calling Parameters
!
!       IN
!           cilm        Spherical harmonic coefficients, with dimensions
!                       (2, lmax+1, lmax+1).
!           lmax        Maximum degree used in the expansion.
!           lat         latitude (degrees).
!           long        longitude (degrees).
!
!       OUT 
!            d          Vector of length nmax of the raw data points.
!
!       OPTIONAL (IN)
!           norm        Spherical harmonic normalization:
!                           (1) "geodesy" (default)
!                           (2) Schmidt
!                           (3) unnormalized
!                           (4) orthonormalized
!           csphase     1: Do not include the phase factor of (-1)^m
!                       -1: Apply the phase factor of (-1)^m.
!           dealloc     If (1) Deallocate saved memory in Legendre function 
!                       routines. Default (0) is not to deallocate memory.
!
!   Dependencies:       PlmBar, PlBar, PlmSchmidt, PlmON, CSPHASE_DEFAULT
!
!   Notes:
!       1.  If lmax is greater than the the maximum spherical harmonic
!           degree of the input file, then this file will be ZERO PADDED!
!           (i.e., those degrees after lmax are assumed to be zero).
!
!   Copyright (c) 2015, Mark A. Wieczorek
!   All rights reserved.
!
!-------------------------------------------------------------------------------
    use SHTOOLS, only: PlmBar, PLegendreA, PlmSchmidt, PlmON, CSPHASE_DEFAULT, MakeGridPoint

    implicit none
    
    real*8, intent(in):: cilm(:,:,:), lat(:), longitude(:)
    real*8, intent(out) :: d(:)
    integer, intent(in) :: nmax, lmax
    integer, intent(in), optional :: norm, csphase, dealloc
    integer :: i, norm_, csphase_, dealloc_

    if (size(cilm(:,1,1)) < 2 .or. size(cilm(1,:,1)) < lmax+1 .or. &
            size(cilm(1,1,:)) < lmax+1) then
        print*, "Error --- MakeGridArray"
        print*, "CILM must be dimensioned as (2, LMAX+1, LMAX+1) " // &
                "where LMAX is ", lmax
        print*, "Input dimension is ", size(cilm(:,1,1)), size(cilm(1,:,1)), &
                size(cilm(1,1,:))
        stop
    end if
        
    if (present(norm)) then
        norm_ = norm
    else
        norm_ = 1
    end if
    
    if (present(csphase)) then
        csphase_ = csphase
    else
        csphase_ = CSPHASE_DEFAULT
    end if
        
    if (present(dealloc)) then
        dealloc_ = dealloc
    else
        dealloc_ = dealloc
    end if
        

    do i = 1, nmax
        d(i) = MakeGridPoint(cilm, lmax, lat(i), longitude(i), norm_, &
                            csphase_, dealloc_)
    end do

end subroutine MakeGridArray
