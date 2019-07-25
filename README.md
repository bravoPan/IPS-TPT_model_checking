# CSE108_IPS_model_checking

## CSE108 prism assignment

Check with [IEEE Xplore](https://ieeexplore.ieee.org/document/8589425/metrics#metrics)

5 members team-work, guys work fun and enjoy it! 😙

The aim is to check the reliability of IPS(indoor positioning systems) using prism, which is adapted from CTMC model provided by CSE108 extra material.

## A real implementation
![](./Pan/real_implementation.png)


## Model realization

### model1

![](./Pan/model1.png)

failure situation:

1. Any of `Sensor` can fail.  If available **sensor < 3**, the whole system is shut down

2. `Input/Main processors` can fail.  The fail can be **permanent** fault or **transient** fault.

3. The processors failure could be divided into two parts:

    - If permanent, the processor can be recovered by rebooting itself.  

    - If I/O processor is unavailable, M will be unable to read data from I or pass instruction to O.  In such case, M will be forced to skip the current operation cycle.  If the number of consecutive cycles skipped exceeds the limit, the system is shut down.

-----

### model2

![](./Pan/model2.png)


1. The failure of `Sensor` is the same of model1.

2. `Input` can fail. If available **processors < 3**, the whole system is shut down. `Main processor` failure is the same as model1.

3. Permanent and transient situation is the same as the model1


## Checking items  

- Panel with different sensors in 24 hours and 30 days
Result: Changing the number of sensors may not be dependable

- Failure rate:

    - the sensor with different failure rate. It could find which time point the         failure rate increase slowly

    - the different failure rate of processor

    - different failure rate of application

- Two models comparison


## Final Paper

[Please Check here](https://github.com/bravoPan/CSE108_IPS_model_checking/blob/master/final_revision.pdf)
