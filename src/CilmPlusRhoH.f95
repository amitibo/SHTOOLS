subroutine CilmPlusRhoH(cilm, gridin, lmax, nmax, mass, d, rho, gridtype, w, &
                                                    zero, plx, n, dref)
!-------------------------------------------------------------------------------
!
!   This routine will compute the potential coefficients associated
!   with the input gridded relief using the method of Wieczorek and
!   Phillips (1998). The input grid must contain the degree-0 term
!   and the computed coefficients will be referenced to the corresonding 
!   degree-0 radius. Note that the array plx is optional, and should not 
!   be precomputed when memory is an issue (i.e., lmax>360). In contrast
!   to CilmPlus, takes into account lateral variations in density by
!   inputing both a relief grid (GRIDIN) and density grid (RHO).
!
!   Calling Parameters
!
!       IN
!           gridin      Input grid to be transformed to spherical harmonics. 
!           lmax        Maximum spherical harmonic degree to compute. For 
!                       gridtype 3 and 4, this must be less than or equal 
!                       to N/2 - 1. 
!           nmax        Order of expansion.
!           mass        Mass of planet.
!           rho         Input grid of the density with same dimensions as 
!                       GRIDIN.
!           gridtype    1 = Gauss-Legendre quadrature grid corresponding 
!                       to LMAX.
!                       2 = N by N Driscoll and Healy grid corresponding 
!                       to LMAX.
!                       3 = N by 2N Driscoll and Healy grid corresponding 
!                       to LMAX.
!                       (4 = 2D Cartesian using MakeGrid2D is not implemented).
!
!       OUT
!           cilm        Output spherical harmonic coefficients with 
!                       dimensions (2, lmax+1, lmax+1).
!           d           The radius that the coefficients are referenced
!                       to. This parameter corresponds to the degree zero term 
!                       of the data.
!
!       OPTIONAL
!           w           Gauss-Legendre points used in the integrations of 
!                       dimension lmax+1.
!           zero        Array of dimension lmax+1 that contains the latitudinal
!                       gridpoints used in the Gauss-Legendre quadrature 
!                       integration scheme. Only needed when PLX is not 
!                       included (determined from a call to SHGLQ).
!           plx         Input array of Associated Legendre Polnomials computed
!                       at the Gauss points (determined from a call to
!                       SHGLQ). If this is not included, then the optional
!                       array zero MUST be inlcuded.
!           N           Number of latitude points in the Driscoll and Healy 
!                       grid. Required for Gridtype 2 and 3.
!           dref        The reference radius used to be used when calculating 
!                       the spherical harmonic coefficients. If not specified, 
!                       this will be set equal to the mean radius of GRIDIN.
!
!   All units assumed to be SI.
!
!   Dependencies:       NGLQSH, SHExpandGLQ, SHExpandDH
!
!   Copyright (c) 2005-2015, Mark A. Wieczorek
!   All rights reserved.
!
!-------------------------------------------------------------------------------
    use SHTOOLS, only: NGLQSH, SHExpandGLQ, SHExpandDH

    implicit none
            
    real*8, intent(in) :: gridin(:,:), mass, rho(:,:)
    real*8, intent(in), optional :: w(:), zero(:), plx(:,:), dref
    real*8, intent(out) :: cilm(:,:,:), d
    integer, intent(in) :: lmax, nmax, gridtype
    integer, intent(in), optional :: n
    real*8 :: prod, pi, scalef
    real*8, allocatable :: cilmn(:, :, :), grid(:, :)
    integer :: j, l, k, nlat, nlong, astat(2), lmax_dh

    pi = acos(-1.0d0)
        
    if (size(cilm(:,1,1)) < 2 .or. size(cilm(1,:,1)) < lmax+1 .or. &
                                    size(cilm(1,1,:)) < lmax+1) then
        print*, "Error --- CilmPlusRhoH"
        print*, "CILM must be dimensioned as (2, LMAX+1, LMAX+1) where " // &
                "LMAX is ",  lmax
        print*, "Input dimension is ", size(cilm(:,1,1)), size(cilm(1,:,1)), &
                                    size(cilm(1,1,:))
        stop
    end if
    
    if (gridtype == 4) then
        print*, "Error --- CilmPlusRhoH"
        print*, "GRIDTYPE 4 (Cartesian obtained from MakeGrid2D) is " // &
                "not allowed."
        stop    
        
    else if (gridtype == 1) then
        if (present(n)) then
            print*, "Error --- CilmPlusRhoH"
            print*, "N can not be present when using GLQ grids."
            stop
        end if
        
        if (present(w) .and. present(zero) .and. present(plx)) then
            print*, "Error --- CilmPlusRhoH"
            print*, "For GLQ grids, either W and ZERO or W and PLX " // &
                    "must be present, but not all three."
            stop
            
        else if (present(w) .and. present(zero)) then
            if (size(w) < lmax + 1) then
                print*, "Error --- CilmPlusRhoH"
                print*, "W must be dimensioned as (LMAX+1) where LMAX is ", lmax
                print*, "Input dimension is ", size(w)
                stop
            end if
            
            if (size(zero) < lmax + 1) then
                print*, "Error --- CilmPlusRhoH"
                print*, "ZERO must be dimensioned as (LMAX+1) " // &
                        "where LMAX is ", lmax
                print*, "Input dimension is ", size(zero)
                stop
            end if
            
        else if (present(plx) .and. present(w)) then
            if (size(w) < lmax + 1) then
                print*, "Error --- CilmPlusRhoH"
                print*, "W must be dimensioned as (LMAX+1) where LMAX is ", lmax
                print*, "Input dimension is ", size(w)
                stop
            end if

            if (size(plx(:,1)) < lmax+1 .or. &
                                    size(plx(1,:)) < (lmax+1)*(lmax+2)/2) then
                print*, "Error --- CilmPlusRhoH"
                print*, "PLX must be dimensioned as (LMAX+1, " // &
                        "(LMAX+1)*(LMAX+2)/2) where LMAX is ", lmax
                print*, "Input dimension is ", size(plx(:,1)), size(plx(1,:))
                stop
            end if
            
        else
            print*, "Error --- CilmPlusRhoH"
            print*, "For GLQ grids, either W and ZERO or W and " // &
                    "PLX must be present"
            stop
            
        end if
        
    else if (gridtype == 2) then
        if (present(w) .or. present(zero) .or. present(plx)) then
            print*, "Error --- CilmPlusRhoH"
            print*, "W, ZERO and PLX can not be present for " // &
                    "Driscoll-Healy grids."
            stop
            
        elseif (.not. present(N)) then
            print*, "Error --- CilmPlusRhoH"
            print*, "N must be present when GRIDTYPE is 2 or 3."
            stop
        end if
    
    else if (gridtype == 3) then
        if (present(w) .or. present(zero) .or. present(plx)) then
            print*, "Error --- CilmPlusRhoH"
            print*, "W, ZERO and PLX can not be present for " // &
                    "Driscoll-Healy grids."
            stop
            
        else if (.not. present(N)) then
            print*, "Error --- CilmPlusRhoH"
            print*, "N must be present when GRIDTYPE is 2 or 3."
            stop
        end if
        
    else
        print*, "Error --- CilmPlusRhoH"
        print*, "GRIDTYPE must be 2 (GLQ), 3 (NxN) or 4 (Nx2N)"
        print*, "Input value is ", gridtype
        stop
        
    end if
    
    if (gridtype == 1) then
        nlat = NGLQSH(lmax)   !  lmax+1
        nlong = 2*lmax+1
        
    else if (gridtype == 2) then
        nlat = N
        nlong = N
        lmax_dh = N/2 - 1
        
        if (lmax > lmax_dh) then
            print*, "Error --- CilmPlusRhoH"
            print*, "For Driscoll-Healy grids, LMAX must be less " // &
                    "than or equal to N/2 -1, where N is ", N
            print*, "Input value of LMAX is ", lmax
            stop
        end if
        
    else if (gridtype == 3) then
        nlat = N
        nlong = 2 * N
        lmax_dh = N/2 - 1
        
        if (lmax > lmax_dh) then
            print*, "Error --- CilmPlusRhoH"
            print*, "For Driscoll-Healy grids, LMAX must be less " // &
                    "than or equal to N/2 -1, where N is ", N
            print*, "Input value of LMAX is ", lmax
            stop
        end if
        
    end if
        
    if (size(gridin(1,:)) < nlong .or. size(gridin(:,1)) < nlat .or. &
                        size(rho(1,:)) < nlong .or. size(rho(:,1)) < nlat) then
        print*, "Error --- CilmPlusRhoH"
        
        if (gridtype == 2) then
            print*, "GRIDIN and RHO must be dimensioned as " // &
                    "(LMAX+1, 2*LMAX+1) where LMAX is ", lmax
            print*, "Input dimension of GRIDIN is ", size(gridin(1,:)), &
                                                size(gridin(:,1))
            print*, "Input dimension of RHO is ", size(rho(1,:)), size(rho(:,1))
            stop
            
        else if (gridtype == 3) then 
            print*, "GRIDIN and RHO must be dimensioned as " // &
                    "(N, N) where N is ", n
            print*, "Input dimension of GRIDIN is ", size(gridin(1,:)), &
                                                size(gridin(:,1))
            print*, "Input dimension of RHO is ", size(rho(1,:)), size(rho(:,1))
            stop
            
        else if (gridtype == 4) then 
            print*, "GRIDIN and RHO must be dimensioned as " // &
                    "(N, 2N) where N is ", n
            print*, "Input dimension of GRIDIN is ", size(gridin(1,:)), &
                                                size(gridin(:,1))
            print*, "Input dimension of RHO is ", size(gridin(1,:)), &
                                                size(gridin(:,1))
            stop
        end if
        
    end if
        
    allocate (cilmn(2, lmax+1, lmax+1), stat=astat(1))
    allocate (grid(nlat, nlong), stat=astat(2))
    
    if (astat(1) /= 0 .or. astat(2) /= 0) then
        print*, "Error --- CilmPlusRhoH"
        print*, "Problem allocating arrays CILMN and GRID", astat(1), astat(2)
        stop
    end if
    
    !---------------------------------------------------------------------------
    !
    !   Do the expansion.
    !
    !---------------------------------------------------------------------------

    grid(1:nlat, 1:nlong) = gridin(1:nlat,1:nlong) 
    cilm = 0.0d0
    cilmn = 0.0d0
    
    ! Determine reference radius, if necessary
    
    if (present(dref)) then
        d = dref
        
    else
        select case (gridtype)
            case (1)
                if (present(plx)) then
                    call SHExpandGLQ(cilmn(1:2,1:lmax+1,1:lmax+1), lmax, &
                        grid(1:nlat,1:nlong), w, plx = plx, norm = 1, &
                        csphase = 1, lmax_calc = 0)
                        
                else
                    call SHExpandGLQ(cilmn(1:2,1:lmax+1,1:lmax+1), lmax, &
                        grid(1:nlat,1:nlong), w, zero=zero, norm = 1, &
                        csphase = 1, lmax_calc = 0)
                end if
                
            case (2)
                call SHExpandDH(grid(1:nlat,1:nlong), n, &
                    cilmn(1:2,1:lmax+1,1:lmax+1), lmax_dh, norm = 1, &
                    sampling = 1, csphase = 1, lmax_calc = 0)
                    
            case (3)
                call SHExpandDH(grid(1:nlat,1:nlong), n, &
                    cilmn(1:2,1:lmax+1,1:lmax+1), lmax_dh, norm = 1, &
                    sampling = 2, csphase = 1, lmax_calc = 0)
                    
        end select

        d = cilmn(1,1,1)   ! use mean radius of relief for reference sphere

    end if
   
    ! Do k = 1 terms first
    
    grid(1:nlat, 1:nlong) = (gridin(1:nlat,1:nlong)-d) * rho(1:nlat,1:nlong) / d
    
    select case (gridtype)
        case (1)
            if (present(plx)) then
                call SHExpandGLQ(cilmn(1:2,1:lmax+1,1:lmax+1), lmax, &
                    grid(1:nlat,1:nlong), w, plx = plx, norm = 1, csphase = 1)
                    
            else
                call SHExpandGLQ(cilmn(1:2,1:lmax+1,1:lmax+1), lmax, &
                    grid(1:nlat,1:nlong), w, zero=zero, norm = 1, csphase = 1)
                    
            end if
            
        case (2)
            call SHExpandDH(grid(1:nlat,1:nlong), n, &
                cilmn(1:2,1:lmax+1,1:lmax+1), lmax_dh, norm = 1, &
                sampling = 1, csphase = 1, lmax_calc = lmax)
                    
        case (3)
            call SHExpandDH(grid(1:nlat,1:nlong), n, &
                cilmn(1:2,1:lmax+1,1:lmax+1), lmax_dh, norm = 1, sampling = 2, &
                csphase = 1, lmax_calc = lmax)
                
    end select

    do l = 0, lmax
        cilm(1:2,l+1,1:l+1) = 4.0d0*pi*(d**3)*cilmn(1:2,l+1,1:l+1) &
                                / mass /dble(2*l+1)
    end do
    
    scalef = maxval(abs(gridin(1:nlat,1:nlong) - d))
    
    do k = 2, nmax
        grid(1:nlat,1:nlong) = rho(1:nlat,1:nlong) * &
                                ((gridin(1:nlat,1:nlong)-d)/scalef)**k
        select case (gridtype)
            case (1)
                if (present(plx)) then
                    call SHExpandGLQ(cilmn(1:2,1:lmax+1,1:lmax+1), lmax, &
                        grid(1:nlat,1:nlong), w, plx=plx, norm = 1, csphase = 1)
                        
                else
                    call SHExpandGLQ(cilmn(1:2,1:lmax+1,1:lmax+1), lmax, &
                        grid(1:nlat,1:nlong), w, zero=zero, norm = 1, &
                        csphase = 1)
                        
                end if
                
            case(2)
                call SHExpandDH(grid(1:nlat,1:nlong), n, &
                    cilmn(1:2,1:lmax+1,1:lmax+1), lmax_dh, norm = 1, &
                    sampling = 1, csphase = 1, lmax_calc = lmax)
                    
            case(3)
                call SHExpandDH(grid(1:nlat,1:nlong), n, &
                    cilmn(1:2,1:lmax+1,1:lmax+1), lmax_dh, norm = 1, &
                    sampling = 2, csphase = 1, lmax_calc = lmax)
                    
        end select
        
        do l = 0, lmax
            prod = 4.0d0*pi*(d**3)/mass * (scalef/d)**k
            
            do j = 1, k
                prod = prod * dble(l+4-j)
            end do
            
            prod = prod/( dble(2*l+1) * dble(l+3) * dble(fact(k)) )
            
            cilm(1:2,l+1,1:l+1) = cilm(1:2,l+1,1:l+1) + &
                                    cilmn(1:2,l+1,1:l+1)*prod
        end do
        
    end do
  
    deallocate(cilmn)
    deallocate(grid)
    
    
    CONTAINS
    
        function fact(i)
        !-----------------------------------------------------------------------
        !
        !   This function computes the factorial of an integer.
        !
        !-----------------------------------------------------------------------
            implicit none
            integer :: i, j
            real*8 :: fact
    
            if (i == 0) then
                fact = 1.0d0    
            else if (i < 0) then
                print*, "Argument to FACT must be positive"
                stop
            else
                fact = 1.0d0
                
                do j = 1, i
                    fact = fact * j
                end do
            end if
            
        end function fact

end subroutine CilmPlusRhoH
