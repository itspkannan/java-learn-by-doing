# GC Analysis in Kubernetes Deployments

The goal of the project is to configure cpu and memory constraints in deployment spec and understand the gc logs for simple application. 

- Capture the gc logs for different version of same application.
- Understand behaviour of different GC.
- Persist data of gc for future comparative analysis. 
  - Stream GC data to kafka
  - Perist the gc data to a timeseries db
- Comparative analysis to determine if the base deployment and testing shows any memory usage and gc anamolies.
  - Dashboard to view the gc trend.
  - Comparative analysis using `plotly`.
  

[Setup](setup.md)
