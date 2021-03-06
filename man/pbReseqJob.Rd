% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/sugar.R
\name{pbReseqJob}
\alias{pbReseqJob}
\title{Create a resequencing job tool wrapper using a function that takes an object
returned by pbreporter() as input.}
\usage{
pbReseqJob(scriptFileName, toolName, func, reportid, reportTitle,
  version = "0.0.1", nproc = 1, distributed = TRUE)
}
\arguments{
\item{scriptFileName}{The name of the R file. (e.g. myTool.R, should be the name of the file that calls this)}

\item{toolName}{What is the name of the tool, should be all lowercase, no special characters.}

\item{reportid}{Name of the report id.}

\item{version}{Default = 0.0.1}

\item{nproc}{How many processors does the tool need?}

\item{distributed}{Should this run on the server or the cluster?}
}
\description{
Create a resequencing job tool wrapper using a function that takes an object
returned by pbreporter() as input.
}

