# IO parsing for TCs and RTCs

# FIXME(mpkocher)(2016-22-2016) Should grab this from DESCRIPTION
PB_COMMANDR_VERSION <- "0.3.6"

#' General func to load JSON from a file
#' @export
loadJsonFromFile <- function(path) {
  logging::loginfo(paste("Loading tool contract from", path))
  if (file.exists(path)) {
    s <- readChar(path, file.info(path)$size)
    d <- jsonlite::fromJSON(s, simplifyDataFrame = FALSE)
    return(d)
  } else {
    msg <- paste("Unable to find json file", "'", path, "'")
    logging::loginfo(msg, "ERROR")
    stop(msg)
  }
}

dToInputType <- function(d) {
  # fileType should be an obj
  return(
    methods::new(
      "InputFileType",
      title = d$title,
      id = d$title,
      fileTypeId = d$file_type_id,
      description = d$description
    )
  )
}

dToOutputType <- function(d) {
  # fileType should be an obj
  return(
    methods::new(
      "OutputFileType",
      title = d$title,
      id = d$title,
      fileTypeId = d$file_type_id,
      description = d$description,
      baseName = d$default_name
    )
  )
}

#' convert the json to ToolContract instance
dToToolContract <- function(d) {
  tc <- d$tool_contract
  taskId <- tc$tool_contract_id
  inputFiles <- Map(dToInputType, tc$input_types)
  outputFiles <- Map(dToOutputType, tc$output_types)
  nproc <- tc$nproc
  isDistributed <- d$tool_contract$is_distributed

  # FIXME, Not Supported yet.
  # - Task Options
  # - Resource Types

  toolContractTask <-
    methods::new(
      "ToolContractTask",
      taskId = taskId,
      inputTypes = inputFiles,
      outputTypes = outputFiles,
      nproc = nproc,
      name = tc$name,
      description = tc$description,
      isDistributed = isDistributed
    )
  driver <- methods::new("ToolDriver", exe = d$driver$exe)
  toolContract <-
    methods::new("ToolContract", task = toolContractTask, driver = driver)
  return(toolContract)
}

#' Load Tool Contract from Path
#' @export
loadToolContractFromPath <- function(path) {
  return(dToToolContract(loadJsonFromFile(path)))
}

#' Convert Tool Contract into list/dict
#' @export
toolContractToD <- function(toolContract) {
  desc <- paste("Tool Contract from ", toolContract@task@taskId)
  authorComment <-
    paste("Created from pbcommandR version ", PB_COMMANDR_VERSION)
  isDistributed <- toolContract@task@isDistributed

  schemaOptions <- list()

  # The 'id' needs to be fixed. ft@fileTypeId_{index} this isn't really used in the
  # R 'quick' model, so it's fine.
  toInputType <- function(ft, i) {
    file_type_id <- ft@fileTypeId
    # This is a bit weak, but will work for now.
    # the "id" needs to be unique
    splitID <- strsplit(ft@fileTypeId, "\\.")[[1]]
    ext <- splitID[length(splitID)]
    #FIXME
    return(list(
      file_type_id = file_type_id,
      id = paste("id", 0, tolower(ext),
                 sep = "_"),
      title = paste("Display name ", file_type_id),
      description = paste("File type ", file_type_id)
    ))
  }

  # The output adds a default output base name (without the extention)
  toOutputType <- function(ft) {
    tmp = toInputType(ft)
    tmp$default_name <- ft@baseName
    return(tmp)
  }

  inputTypes <- Map(toInputType, toolContract@task@inputTypes)
  outputTypes <- Map(toOutputType, toolContract@task@outputTypes)

  jdriver <-
    list(serialization = "json", exe = toolContract@driver@exe)

  jt <-
    list(
      task_type = "pbsmrtpipe.task_types.standard",
      resource_types = list(),
      description = desc,
      name = toolContract@task@name,
      nproc = toolContract@task@nproc,
      is_distributed = isDistributed,
      schema_options = schemaOptions,
      tool_contract_id = toolContract@task@taskId,
      input_types = inputTypes,
      output_types = outputTypes,
      comment = authorComment
    )

  j <-
    list(
      version = PB_COMMANDR_VERSION,
      driver = jdriver,
      tool_contract_id = toolContract@task@taskId,
      tool_contract = jt
    )

  return(j)
}

#' Write Tool Contract to JSON file
#' @param toolContract Tool Contract
#' @export
writeToolContract <- function(toolContract, jsonPath) {
  # TO FIX in the model - task options - task type - is distributed
  logging::logdebug(paste(
    "Writing tool contract",
    toolContract@task@taskId,
    "to",
    jsonPath
  ))

  j <- toolContractToD(toolContract)

  jsonToolContract <- jsonlite::toJSON(j, pretty = TRUE, auto_unbox = TRUE)

  cat(jsonToolContract, file = jsonPath)
  return(jsonToolContract)
}

#' Convert a dict to a Resolved Task Contract
dictToResolvedToolContract <- function(d) {
  t <- d$resolved_tool_contract
  taskId <- t$tool_contract_id

  # List of absolute paths
  inputFiles <- t$input_files
  # List of absolute Paths
  outputFiles <- t$output_files

  nproc <- t$nproc

  taskType <- "NA"
  taskOptions <- list()
  resources <- list()

  resolvedToolContractTask <-
    methods::new(
      "ResolvedToolContractTask",
      taskId = taskId,
      taskType = taskType,
      inputFiles = inputFiles,
      outputFiles = outputFiles,
      taskOptions = taskOptions,
      nproc = nproc,
      resources = resources
    )
  driver <- methods::new("ToolDriver", exe = d$driver$exe)
  methods::new("ResolvedToolContract", task = resolvedToolContractTask, driver = driver)
}

#' Load a Resolved Tool contract from json file
#' @export
loadResolvedToolContractFromPath <- function(path) {
  logging::loginfo(paste("Loading resolved tool contract from ", path))
  return(dictToResolvedToolContract(loadJsonFromFile(path)))
}

dictToReseqCondition <- function(d) {
  return(
    methods::new(
      "ReseqCondition",
      condId = d$condId,
      subreadset = d$subreadset,
      alignmentset = d$alignmentset,
      referenceset = d$referenceset
    )
  )
}


dictToReseqConditions <- function(d) {
  pipelineId <- d$pipelineId
  conditions <- lapply(d$conditions, dictToReseqCondition)
  return(methods::new(
    "ReseqConditions",
    pipelineId = pipelineId,
    conditions = conditions
  ))
}

#' Load Condition
#' @export
loadReseqConditionsFromPath <- function(path) {
  logging::loginfo(paste("Loading ReseqConditions from ", path))
  return(dictToReseqConditions(loadJsonFromFile(path)))
}
