library(yaml)
library(rmarkdown)
library(pander)

root_dir <- normalizePath("..")

collections <- yaml.load_file(file.path("..", "_config.yml"))$collections

collection_dirs <- file.path(root_dir, "problem_sets", collections$problem_sets$order)

output_dir <- paste0("_", "problem_sets")

unlink(list.files(file.path(root_dir, output_dir)), recursive = TRUE)

counter <- 1
for (x in collection_dirs) {
  prefix <- paste0("PS", counter, " -")
  ## Enumerate and render all Rmarkdown files
  rmd_files <- list.files(path = x, pattern = "*\\.Rmd$", full.names = TRUE)
  
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
                        as.yaml(list(title = paste0("Problem Set ", counter, ": ", basename(x)),
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

  post_file <- file.path(root_dir, "_problem_sets", paste0(basename(x), ".md"))
  writeLines(c(yaml_header, body), con=post_file, sep="")
  counter <- counter + 1 # Get next lab number
}


all_labs <- yaml.load_file(file.path("..", "_config.yml"))$collections$labs$order

## Make static files dir if we need to
output_dir <- file.path("..", "labs")
if ( !file.exists(output_dir) ) {
  dir.create(output_dir)
}

# Make collections dir if we need to
collections_dir <- file.path("..", "_labs")
if ( !file.exists(collections_dir) ) {
  dir.create(collections_dir)
}

counter <- 1
for (lab in all_labs) {
  
  ## Find and switch to lab files directory
  lab_dir <- file.path("..", 'labs_source', lab)
  old <- setwd(lab_dir)
  
  ## Enumerate and render all Rmarkdown files
  rmd_files <- list.files(pattern = "*\\.Rmd$", full.names = TRUE)
  for (file in rmd_files) {
    rmarkdown::render(file, envir = new.env())
  }
  
  # Switch back to old wd, since all our paths were relative to that directory.
  setwd(old)
  
  ## Copy the lab directory from the source to the site output folder
  file.copy(from=lab_dir, to=output_dir, recursive = TRUE)
  
  ## Rename the lab output directory in numerical sequence
  numerical_lab_dir <- file.path(output_dir, paste0("lab", counter))
  if (file.exists(numerical_lab_dir)) {
    unlink(numerical_lab_dir, recursive = TRUE)
  }
  file.rename(from=file.path(output_dir, lab), to=numerical_lab_dir)
  
  ## Remove cache from site output
  cache <- list.files(numerical_lab_dir, pattern = "_cache$", full.names = TRUE)
  if (!identical(cache, character(0))) {
    unlink(cache, recursive = TRUE)
  }
  
  ## Remove solutions from site output
  solutions <- list.files(numerical_lab_dir, pattern = "solution", full.names = TRUE)
  if (!identical(solutions, character(0))) {
    unlink(solutions, recursive = TRUE)
  }
  
  
  ## Rename lab Rmd template and assignment file to have informative names
  template <- list.files(file.path(numerical_lab_dir), pattern = "exercises.Rmd", full.names = TRUE, ignore.case = TRUE)
  assignment <- list.files(file.path(numerical_lab_dir), pattern = "exercises.html", full.names = TRUE, ignore.case = TRUE)
  file.rename(from=template, to=sub("exercises", paste0("Lab ", counter, " Exercises Template"), template, ignore.case = TRUE))
  file.rename(from=assignment, to=sub("exercises", paste0("Lab ", counter, " Exercises"), assignment, ignore.case = TRUE))
  
  ## Rename slides to have informative names
  slides <- list.files(file.path(numerical_lab_dir), pattern = "slides\\.[[:alnum:]]+$", full.names = TRUE, ignore.case = TRUE)
  file.rename(from=slides, to=sub("slides", lab, slides, ignore.case = TRUE))
  
  ## Generate "post" with links for labs collection
  yaml_header <- paste0("---\n",
                        as.yaml(list(title = paste0("Lab ", counter, " - ", lab),
                                     author = "Will Hopper"
                        )
                        ),
                        "---\n"
  )
  
  slides_final_path <- file.path("labs", paste0("lab", counter), paste0(lab, ".html"))
  exercises_final_path <- file.path("labs", paste0("lab", counter), paste0("Lab ", counter, " Exercises.html"))
  template_final_path <- file.path("labs", paste0("lab", counter), paste0("Lab ", counter, " Exercises Template.Rmd"))
  
  body <- list(pandoc.link.return(url = slides_final_path, text = paste0("Lab ", counter, " Slides")),
               pandoc.link.return(url = exercises_final_path, text = paste0("Lab ", counter, " Exercises")),
               pandoc.link.return(url = template_final_path, text = paste0("Lab ", counter, " Exercises Template"))
  )
  
  lab_file_exists <- vapply(file.path(root_dir, c(slides_final_path, exercises_final_path, template_final_path)),
                            file.exists,
                            logical(1)
  )
  body <- pandoc.list.return(body[lab_file_exists], add.end.of.list = FALSE)
  
  post_file <- file.path("..", "_labs", paste0(lab, ".md"))
  if (file.exists(post_file)) {
    file.remove(post_file)
  }
  writeLines(c(yaml_header, body), con=post_file, sep="")
  counter <- counter + 1 # Get next lab number
}


