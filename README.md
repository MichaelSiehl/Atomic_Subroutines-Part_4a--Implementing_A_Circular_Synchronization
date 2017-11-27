# Atomic_Subroutines-Part_4a--Implementing_A_Circular_Synchronization
Fortran 2008 coarray programming with unordered execution segments (user-defined ordering) and customized synchronization procedures - Atomic Subroutines - Part 4a: How to cope with unreliable data transfers with low-level PGAS programming - allow for safe remote data movement among a number of coarray images. Implementing a circular synchronization.

# Overview
See here for the first part: https://github.com/MichaelSiehl/Atomic_Subroutines-Part_4--How_To_Cope_With_Unreliable_Data_Transfers <br />

Sometimes it may be required that a (customized) synchronization process does synchronize with itself to allow for successful remote data transfer through atomic subroutines.<br /> 

In the first part (see the above link) we did implement a customized (or user-defined) version of (Fortran 2018-like) EventPost and EventWait synchronization procedures. Under some conditions these may not work properly. (Example: With OpenCoarrays/gfortran at program start when the execution of the customized EventPost (atomic_define) does temporal precede the execution of the customized EventWait (atomic_ref)).<br />

This GitHub repository contains a first implementation of a customized synchronization procedure that can synchronize itself by applying a circular (or ring) synchronization. Again, only few lines of Fortran code were required to accomplish that. <br />

# How it works
The codes in the src folder should be compiled and run with OpenCoarray/gfortran unsing 6 coarray images. (The codes can also be compiled with ifort since version 18 update 1. But with ifort there are no failures of the remote data transfers through atomic subroutines on a shared memory computer yet. Therefore we use OpenCoarrays/gfortran to show the direct effect of a circular synchronization on a shared memory computer.)<br />

The Main.f90 contains a simple test case that we do compile with different settings from the code. The test case does execute a customized EventWait on coarray image 1, a customized EventPost on coarray images 3-6 resp., and a remotely initiated synchronization abort on coarray image 2 (which itself is not part of the synchronization process) after 2 seconds. (The abort does only occur if the synchronization process is still running after 2 seconds). See the following outputs from distinct program runs with different settings from the code in Main.f90:<br />

#1.
We run the test case as non-circular synchronization (the logActivateCircularSynchronization argument is set to false for calling the customized EventPost and EventWait). We do execute the customized EventWait on image 1 without any time delay. The calls to the customized EventPost on coarray images 3-6 are getting executed with a delay of 0.5 seconds. Thus, the EventWait does temporal precede the calls to EventPost.<br />

Main.f90:<br />
```fortran
  !
  !******************************************************************
  !** on image 1: initiate a customized EventWait *******************
  !******************************************************************
  !
  if (this_image() == 1) then ! do a customized Event Wait on image 1
    !
    intNumberOfRemoteImages = 4
    intA_RemoteImageNumbers = (/3,4,5,6/)
    !
    ! wait some time:
    call cpu_time(reaTime1)
    do
      call cpu_time(reaTime2)
      reaTimeShift = reaTime2 - reaTime1
      if (reaTimeShift > 0.0) exit ! ! waiting time in seconds
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
                logActivateCircularSynchronization = .false.)
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
      if (reaTimeShift > 0.5) exit ! waiting time in seconds
    end do
    !
    intRemoteImageNumber = 1
    intImageActivityFlag = OOOPimscEnum_ImageActivityFlag % InitiateASynchronization
    intAdditionalAtomicValue = this_image() * 2 ! only a test case
    intEnumStepWidth = OOOPimscEnum_ImageActivityFlag % Enum_StepWidth ! only for error checking
    ! - signal to the remote image (image 1) that this image is now in state 'InitiateASynchronization':
    !
    call OOOPimscEventPostScalar_intImageActivityFlag99_CA (OOOPimscImageStatus_CA_1, intImageActivityFlag, &
                         intRemoteImageNumber, intArrayIndex = this_image(), logExecuteSyncMemory = .true., &
                         intAdditionalAtomicValue = intAdditionalAtomicValue, intEnumStepWidth = intEnumStepWidth, &
                         logActivateCircularSynchronization = .false.)
  end if
  !
```
Output from a program run:
```fortran
  invovled remote images:                        3           4           5           6
 and the additional atomic values:              6           8          10          12
 remote abort of synchronization (TRUE/FALSE): F
 remote image that did the abort:           0
 number of successful remote synchronizations:           4
 the successful image numbers:           4           5           3           6
 number of failed remote synchronizations:           0
 the failed image numbers:           0           0           0           0
```
Here, the 'remote abort of synchronization status' is FALSE. Thus, the synchronization process as a whole did complete successfully before the synchronization abort was initiated remotely.<br />
