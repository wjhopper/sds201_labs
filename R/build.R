library(yaml)
library(rmarkdown)
library(pander)

root_dir <- normalizePath("..")

collections <- yaml.load_file(file.path("..", "_config.yml"))$collections

#### Building Problem Sets Collection ####
problem_sets <- collections$problem_sets$order

# Set output dir. Create it if needed, otherwise clean it out
output_dir <- paste0("_", "problem_sets")
if ( !file.exists(file.path(root_dir, output_dir)) ) {
  dir.create(output_dir)
} else {
  unlink(list.files(file.path(root_dir, output_dir),full.names = TRUE),
         recursive = TRUE
         )
}

counter <- 1
for (pset in problem_sets) {

  pset_path <- file.path(root_dir, "problem_sets", pset)
  prefix <- paste0("PS", counter, " -")
  ## Enumerate and render all Rmarkdown files
  rmd_files <- list.files(path = pset_path, pattern = "*\\.Rmd$", full.names = TRUE)

  for (raw_rmd in rmd_files) {

    rendered_output <- rmarkdown::render(raw_rmd, envir = new.env())

    if (!grepl("solution", raw_rmd, fixed = TRUE)) {
      destination_paths <- sapply(c(raw_rmd, rendered_output),
                                  function(x) { file.path(root_dir, output_dir, paste(prefix, basename(x))) }
                                  )
      copied_succesfully <- file.copy(c(raw_rmd, rendered_output), destination_paths)
    }

  }

  yaml_header <- paste0("---\n",
                        as.yaml(list(title = paste0("Problem Set ", counter, ": ", pset),
                                     author = "Will Hopper"
                                     )
                               ),
                        "---\n"
                        )

  relative_urls <- sub(root_dir, "", destination_paths, fixed = TRUE)
  relative_urls <- paste0("{{site.baseurl}}", sub("^/_", "/", relative_urls))

  body <- list(pandoc.link.return(url = grep("\\.html$", relative_urls, ignore.case = TRUE, value = TRUE),
                                  text = paste("Problem Set", counter, "Exercises")
                                  ),
               pandoc.link.return(url = grep("\\.rmd$", relative_urls, ignore.case = TRUE, value=TRUE),
                                  text = paste("Problem Set", counter, "Template")
                                  )
               )

  body <- pandoc.list.return(body, add.end.of.list = FALSE)

  post_file <- file.path(root_dir, "_problem_sets", paste0(pset, ".md"))
  writeLines(c(yaml_header, body), con=post_file, sep="")
  counter <- counter + 1 # Get next lab number
}


#### Building Problem Sets Collection ####
labs <- collections$labs$order

# Set output dir. Create it if needed, otherwise clean it out
output_dir <- paste0("_", "labs")
if ( !file.exists(file.path(root_dir, output_dir)) ) {
  dir.create(output_dir)
} else {
  unlink(list.files(file.path(root_dir, output_dir),full.names = TRUE),
         recursive = TRUE
  )
}

counter <- 1
for (lab in labs) {
  
  lab_dir <- file.path(root_dir, "labs", lab)
  prefix <- paste0("Lab", counter, " -")
  
  ## Enumerate and render all Rmarkdown files
  rmd_files <- list.files(path = lab_dir, pattern = "*\\.Rmd$", full.names = TRUE)
  for (raw_rmd in rmd_files) {
    rendered_output <- rmarkdown::render(raw_rmd, envir = new.env())
  }
  
  ## Copy the lab directory to the collection folder
  ## We can't recursively copy a folder to a new name
  ## So we create the new location, list the files in lab directory, and copy those to the new location
  ## in order the achieve the "copy and rename" effect. Maybe an actual copy and rename would be faster?
  ## But, at this way we can remove the .Rmd file and the knitr cache from the list of to be copied files
  destination_dir <- file.path(root_dir, output_dir, gsub(" ", "_", lab))
  success <- dir.create(destination_dir)
  files_to_copy <- list.files(lab_dir, full.names = TRUE)
  files_to_copy <- grep("_cache$|\\.Rmd$", files_to_copy, invert = TRUE, value = TRUE)
  success <- file.copy(files_to_copy, to = destination_dir, recursive = TRUE)
  
  ## Rename slides to have informative names
  # slides <- list.files(destination_dir, pattern = "slides\\.[[:alpha:]]+$", full.names = TRUE, ignore.case = TRUE)
  # file.rename(from=slides, to=sub("slides", lab, slides, ignore.case = TRUE))
  
  ## Generate "post" with links for labs collection
  yaml_header <- paste0("---\n",
                        as.yaml(list(title = paste0("Lab ", counter, " - ", lab),
                                     author = "Will Hopper"
                                     )
                        ),
                        "---\n"
  )

  slides_relative_url <- sub(root_dir, "", list.files(destination_dir, pattern="\\.html$", full.names = TRUE))
  slides_relative_url <- paste0("{{site.baseurl}}", sub("^/_", "/", slides_relative_url))
  
  body <- list(pandoc.link.return(url = slides_relative_url, text = paste0("Lab ", counter, " Slides")))
  body <- pandoc.list.return(body, add.end.of.list = FALSE)
  
  post_file <- file.path("..", "_labs", paste0(lab, ".md"))
  if (file.exists(post_file)) {
    file.remove(post_file)
  }
  writeLines(c(yaml_header, body), con=post_file, sep="")
  counter <- counter + 1 # Get next lab number
}


