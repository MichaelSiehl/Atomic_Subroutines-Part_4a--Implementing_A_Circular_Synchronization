! https://github.com/MichaelSiehl/Atomic_Subroutines-Part_4a--Implementing_A_Circular_Synchronization
!
program Main
  ! a simple test-case for the customized EventPost/EventWait circular synchronization
  ! (customized Event Wait with integrated synchronization abort and
  ! with integrated synchronization diagnostics)
  !
  use OOOGglob_Globals
  use OOOEerro_admError
  use OOOPimsc_admImageStatus_CA
  implicit none
  !
  integer(OOOGglob_kint) :: intNumberOfRemoteImages
  integer(OOOGglob_kint), dimension (1:4) :: intA_RemoteImageNumbers ! please compile and run this coarray
                                                                     ! program with 6 coarray images
  integer(OOOGglob_kint) :: intImageActivityFlag
  integer(OOOGglob_kint), dimension (1:4, 1:2) :: intA_RemoteImageAndItsAdditionalAtomicValue
  integer(OOOGglob_kint) :: intRemoteImageNumber
  integer(OOOGglob_kint) :: intEnumStepWidth
  integer(OOOGglob_kint) :: intAdditionalAtomicValue
  integer(OOOGglob_kint) :: intCheckRemoteAbortOfSynchronization
  logical(OOOGglob_klog) :: logRemoteAbortOfSynchronization
  integer(OOOGglob_kint) :: intRemoteImageThatDidTheAbort
  integer(OOOGglob_kint) :: intNumberOfSuccessfulRemoteSynchronizations
  integer(OOOGglob_kint), dimension (1:4) :: intA_TheSuccessfulImageNumbers
  integer(OOOGglob_kint) :: intNumberOfFailedRemoteSynchronizations
  integer(OOOGglob_kint), dimension (1:4) :: intA_TheFailedImageNumbers
  integer(OOOGglob_kint) :: intCount
  real(OOOGglob_krea) :: reaTime1, reaTime2, reaTimeShift
  !
  !******************************************************************
  !** on image 1: initiate a customized EventWait *******************
  !******************************************************************
  !
  if (this_image() == 1) then ! do a customized EventWait on image 1
    !
    intNumberOfRemoteImages = 4
    intA_RemoteImageNumbers = (/3,4,5,6/)
    !
    ! wait some time:
    call cpu_time(reaTime1)
    do
      call cpu_time(reaTime2)
      reaTimeShift = reaTime2 - reaTime1
      if (reaTimeShift > 0.5) exit ! ! waiting time in seconds
    end do
    ! *****
    ! customized EventWait with emergency exit enabled (due to the intCheckRemoteAbortOfSynchronization
    ! argument).
    ! Wait until all the involved remote image(s) do signal that they are in status InitiateASynchronization.
    ! A circular EventWait-EventPost (customized) synchronization is activated by the logActivateCircularSynchronization
    ! argument.
    intImageActivityFlag = OOOPimscEnum_ImageActivityFlag % InitiateASynchronization
    intCheckRemoteAbortOfSynchronization = OOOPimscEnum_ImageActivityFlag % RemoteAbortOfSynchronization
    !
    call OOOPimscEventWaitScalar_intImageActivityFlag99_CA (OOOPimscImageStatus_CA_1, intImageActivityFlag, &
                intNumberOfRemoteImages, intA_RemoteImageNumbers, &
                intA_RemoteImageAndItsAdditionalAtomicValue = intA_RemoteImageAndItsAdditionalAtomicValue, &
                intCheckRemoteAbortOfSynchronization = intCheckRemoteAbortOfSynchronization, &
                logRemoteAbortOfSynchronization = logRemoteAbortOfSynchronization, &
                intRemoteImageThatDidTheAbort = intRemoteImageThatDidTheAbort, &
                intNumberOfSuccessfulRemoteSynchronizations = intNumberOfSuccessfulRemoteSynchronizations, &
                intA_TheSuccessfulImageNumbers = intA_TheSuccessfulImageNumbers, &
                intNumberOfFailedRemoteSynchronizations = intNumberOfFailedRemoteSynchronizations, &
                intA_TheFailedImageNumbers = intA_TheFailedImageNumbers, &
                logActivateCircularSynchronization = .true.)
    !
    write(*,*) 'invovled remote images:             ', intA_RemoteImageAndItsAdditionalAtomicValue(:,1)
    write(*,*) 'and the additional atomic values:   ', intA_RemoteImageAndItsAdditionalAtomicValue(:,2)
    write(*,*) 'remote abort of synchronization (TRUE/FALSE):', logRemoteAbortOfSynchronization
    write(*,*) 'remote image that did the abort:', intRemoteImageThatDidTheAbort
    write(*,*) 'number of successful remote synchronizations:', intNumberOfSuccessfulRemoteSynchronizations
    write(*,*) 'the successful image numbers:', intA_TheSuccessfulImageNumbers
    write(*,*) 'number of failed remote synchronizations:', intNumberOfFailedRemoteSynchronizations
    write(*,*) 'the failed image numbers:', intA_TheFailedImageNumbers
  end if
  !
  !******************************************************************
  !** on image 2: do a synchronization abort after 2 seconds ********
  !******************************************************************
  !
  if (this_image() == 2) then ! image 2 is not involved with the synchronization itself,
                              ! but only to abort the customized Event Wait synchronization on image 1:
    ! wait some time:
    call cpu_time(reaTime1)
    do
      call cpu_time(reaTime2)
      reaTimeShift = reaTime2 - reaTime1
      if (reaTimeShift > 2.0) exit ! ! waiting time in seconds
    end do

    ! do abort the customized EventWait on image 1:
    intRemoteImageNumber = 1
    intImageActivityFlag = OOOPimscEnum_ImageActivityFlag % RemoteAbortOfSynchronization
    call OOOPimscEventPostScalar_intImageActivityFlag99_CA (OOOPimscImageStatus_CA_1, intImageActivityFlag, &
                         intRemoteImageNumber, logExecuteSyncMemory = .true., &
                         intAdditionalAtomicValue = this_image())
    do intCount = 3, 6
      ! do abort the customized EventPost on images 3-6:
      intRemoteImageNumber = intCount
      intImageActivityFlag = OOOPimscEnum_ImageActivityFlag % RemoteAbortOfSynchronization
      call OOOPimscEventPostScalar_intImageActivityFlag99_CA (OOOPimscImageStatus_CA_1, intImageActivityFlag, &
                         intRemoteImageNumber, logExecuteSyncMemory = .true., &
                         intAdditionalAtomicValue = this_image())
    end do
  end if
  !
  !******************************************************************
  !** on all other images: do a customized EventPost ****************
  !******************************************************************
  !
  if (this_image() > 2) then
  ! on all other images do a customized EventPost as part of the synchronization:
    !
    ! wait some time:
    call cpu_time(reaTime1)
    do
      call cpu_time(reaTime2)
      reaTimeShift = reaTime2 - reaTime1
      if (reaTimeShift > 0.0) exit ! waiting time in seconds
    end do
    !
    intRemoteImageNumber = 1
    intImageActivityFlag = OOOPimscEnum_ImageActivityFlag % InitiateASynchronization
    intAdditionalAtomicValue = this_image() * 2 ! only a test case
    intEnumStepWidth = OOOPimscEnum_ImageActivityFlag % Enum_StepWidth ! only for error checking
    ! signal to the remote image (image 1) that this image is now in state 'InitiateASynchronization':
    call OOOPimscEventPostScalar_intImageActivityFlag99_CA (OOOPimscImageStatus_CA_1, intImageActivityFlag, &
                         intRemoteImageNumber, intArrayIndex = this_image(), logExecuteSyncMemory = .true., &
                         intAdditionalAtomicValue = intAdditionalAtomicValue, intEnumStepWidth = intEnumStepWidth, &
                         logActivateCircularSynchronization = .true.)
  end if
  !
  !******************************************************************
  !
!  write (*,*) 'execution finsished on image ', this_image()
  !
end program Main
