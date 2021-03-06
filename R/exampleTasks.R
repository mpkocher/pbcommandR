# Example Task for Development

# This to add to the NAMESPACE via devtools
#' @importFrom stats lm
#' @importFrom stats rnorm
NULL

#' Example Task for testing
#' inputs = [FileTypes.Fasta]
#' outputs = [FileTypes.Fasta]
#' @export
examplefilterFastaTask <- function(pathToFasta, filteredFasta, minSequenceLength) {
  logging::loginfo(paste("Writing filtered fasta to ", filteredFasta))
  write(">r1\nACGT\n>r2\nACCCGGTTT\n", filteredFasta)
  return(0)
}

#' @title Example Plot Group
#' @param outputPath = Abspath to output image, must be png.
#' @export
getExamplePlotGroup <- function(outputPath) {
  plotGroupId <- "plotgroup_a"

  # taken from
  # http://www.cookbook-r.com/Graphs/Scatterplots_(ggplot2)/
  set.seed(955)
  dat <- data.frame(cond = rep(c("A", "B"), each=10),
                    xvar = 1:20 + stats::rnorm(20,sd=3),
                    yvar = 1:20 + stats::rnorm(20,sd=3))

  toPrint = ggplot2::ggplot(dat, ggplot2::aes(x=xvar, y=yvar)) +
    ggplot2::geom_point(shape=1) +
    ggplot2::geom_smooth(method=stats::lm)

  ggplot2::ggsave(outputPath, plot = toPrint)

  logging::loginfo(paste("wrote image to ", outputPath, sep = ""))
  
  plotCaption <- "Example Plot Group Caption"
  
  basePlotFileName <- basename(outputPath)
  # see the above comment regarding ids. The Plots must always be provided
  # as relative path to the output dir
  p1 <- methods::new("ReportPlot", id = "dev_example", image = basePlotFileName, title = "Example Plot", caption = plotCaption)
  pg <- methods::new("ReportPlotGroup", id = plotGroupId, plots = list(p1), title = "Example Plot Group Title")
  return(pg)
}

#' Example Task for Testing with emitting a report
#'
#' inputs = [FileTypes.Fasta]
#' outputs = [FileTypes.Report]
#' @export
examplefastaReport <- function(pathToFasta, reportPath) {
  logging::loginfo(paste("loading fasta file ", pathToFasta))
  logging::loginfo(paste("will be writing report to ", reportPath))

  imageName <- "report_plot.png"

  reportDir <- dirname(reportPath)
  imagePath <- file.path(reportDir, imageName)

  # This is a simple way to expose the Tool version in the report  
  # FIXME(mpkocher)(2016-7-22) Currently report attributes only support Numeric types
  reportAttribute <- methods::new("Attribute", id = "pbcommand_version", name = "pbcommandR Version", value = 3.46)

  reportUUID <- uuid::UUIDgenerate()
  # report ids must be lower case and only match \
  reportId <- "pbcommandr_dev_fasta"
  # This is the Report Schema Version
  version <- PB_REPORT_SCHEMA_VERSION
  tables <- list()
  attributes <- list(reportAttribute)
  plotGroups <- list(getExamplePlotGroup(imagePath))


  report <- methods::new("Report",
  uuid = reportUUID,
  version = version,
  id = reportId,
  plotGroups = plotGroups,
  attributes = attributes,
  tables = tables)

  writeReport(report, reportPath)
  logging::loginfo(paste("Wrote report to ", reportPath))
  return(0)
}

# This can be done here or in a separate file There can be a single registry for
# all tasks, or subparser-eseque model to group tasks

# Define the RTC -> main funcs. Example funcs are defined in exampleTasks.R
runFilterFastaRtc <- function(rtc) {
  minLength <- 25
  return(examplefilterFastaTask(rtc@task@inputFiles[1], rtc@task@outputFiles[1],
    minLength))
}

runFastaReportRtc <- function(rtc) {
  return(examplefastaReport(rtc@task@inputFiles[1], rtc@task@outputFiles[1]))
}

# Import your function from library code
runHelloWorld <- function(inputTxt, outputTxt) {
  msg <- paste("Hello World. Input File ", inputTxt)
  cat(msg, file = outputTxt)
  return(0)
}

# Wrapper to convert Resolved Tool Contract to your library func
runHelloWorldRtc <- function(rtc) {
  return(runHelloWorld(rtc@task@inputFiles[1], rtc@task@outputFiles[1]))
}

# Example populated Registry for testing
#' @export
exampleToolRegistryBuilder <- function() {
  # The driver is what pbsmrtpipe will call with the path to resolved tool contract
  # JSON file FIXME. Not sure how to package exes with R to create a 'console entry
  # point' in python parlance
  # FIXME. There's an extra shell layer to get packrat loaded so the exampleHelloWorld.R
  # can be called correctly.
  r <- registryBuilder(PB_TOOL_NAMESPACE, "exampleHelloWorld.R run-rtc ")
  # could be more clever and use partial application for registry, but this is fine
  registerTool(r, "filter_fasta", "0.1.1", c(FileTypes$FASTA), c(FileTypes$FASTA),
    1, FALSE, runFilterFastaRtc)
  registerTool(r, "fasta_report", "0.1.1", c(FileTypes$FASTA), c(FileTypes$REPORT),
    1, FALSE, runFastaReportRtc)
  registerTool(r, "hello_world", "0.1.1", c(FileTypes$TXT), c(FileTypes$TXT), 1,
    FALSE, runHelloWorldRtc)
  return(r)
}

# Run from a Resolved Tool Contract JSON file -> Rscript /path/to/exampleDriver.R
# run-rtc /path/to/rtc.json Emit Registered Tool Contracts to JSON -> Rscript
# /path/to/exampleDriver.R emit-tc /path/to/output-dir then make Tool Contracts
# JSON accessible to pbsmrtpipe Builds a commandline wrapper that will call your
# driver q(status=mainRegisteryMainArgs(exampleToolRegistryBuilder()))
