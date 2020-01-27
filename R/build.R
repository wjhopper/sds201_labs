library(yaml)
library(rmarkdown)
library(pander)

all_labs <- yaml.load_file(file.path("..", "/_config.yml"))$collections$labs$order

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
    rmarkdown::render(file)
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
  
  ## Remove solutions from site output
  solutions <- list.files(numerical_lab_dir, pattern = "solution", full.names = TRUE)
  file.remove(solutions)
  
  ## Rename lab Rmd template and assignment file to have informative names
  template <- list.files(file.path(numerical_lab_dir), pattern = "exercises.Rmd", full.names = TRUE, ignore.case = TRUE)
  assignment <- list.files(file.path(numerical_lab_dir), pattern = "exercises.html", full.names = TRUE, ignore.case = TRUE)
  file.rename(from=template, to=sub("exercises", paste0("Lab ", counter, " Exercises Template"), template, ignore.case = TRUE))
  file.rename(from=assignment, to=sub("exercises", paste0("Lab ", counter, " Exercises"), assignment, ignore.case = TRUE))
  
  ## Rename slides to have informative names
  slides <- list.files(file.path(numerical_lab_dir), pattern =  "slides.*", full.names = TRUE, ignore.case = TRUE)
  file.rename(from=slides, to=sub("slides", lab, slides, ignore.case = TRUE))
  
  ## Generate "post" with links for labs collection
  yaml_header <- paste0("---\n",
                        as.yaml(list(title = paste0("Lab ", counter, " - ", lab),
                                     author = "Will Hopper"
                                     )
                               ),
                        "---\n"
                        )
  body <- list(pandoc.link.return(paste0("labs/lab", counter, "/", lab, ".html"), paste0("Lab ", counter, " Slides")),
               pandoc.link.return(paste0("labs/lab", counter, "/Lab ", counter, " Exercises.html"), paste0("Lab ", counter, " Exercises")),
               pandoc.link.return(paste0("labs/lab", counter, "/Lab ", counter, " Exercises Template.Rmd"), paste0("Lab ", counter, " Exercises Template"))
               )
  body <- pandoc.list.return(body, add.end.of.list = FALSE)
  
  post_file <- file.path("..", "_labs", paste0(lab, ".md"))
  if (file.exists(post_file)) {
    file.remove(post_file)
  }
  writeLines(c(yaml_header, body), con=post_file, sep="")
}
