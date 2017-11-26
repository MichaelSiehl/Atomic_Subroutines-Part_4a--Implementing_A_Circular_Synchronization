# Atomic_Subroutines-Part_4a--Implementing_A_Circular_Synchronization
Fortran 2008 coarray programming with unordered execution segments (user-defined ordering) and customized synchronization procedures - Atomic Subroutines - Part 4a: How to cope with unreliable data transfers with low-level PGAS programming - allow for safe remote data movement among a number of coarray images. Implementing a circular synchronization.

# Overview
See here for the first part: https://github.com/MichaelSiehl/Atomic_Subroutines-Part_4--How_To_Cope_With_Unreliable_Data_Transfers <br />

Sometimes it may be required that a (customized) synchronization process does synchronize itself to allow for successful remote data movement through atomic subroutines.<br /> 

In the first part (see the above link) we did implement a customized (or user-defined) version of (Fortran 2018-like) EventPost and EventWait synchronization procedures. Under some conditions these do not work properly. (Example: With OpenCoarrays/gfortran at program start when the execution of the customized EventPost (atomic_define) does temporal precede the execution of the customized EventWait (atomic_ref).<br />

This GitHub repository contains a first implementation of a customized synchronization procedure that can synchronize itself by applying a circular (or ring) synchronization. <br />
