#calculates MOM_binary (eventually add upper and lower MOM bounds?)
#MOM is calculated as the layer where DO is < 2mg/L (for now)
#17Aug2023 HLW

if (!require("pacman"))install.packages("pacman")
pacman::p_load(utils, tidyverse)

targets_generation_daily_MOM <- function(current_file, historic_file){
  
  #read in current CTD data
  #PLACEHOLDER for pulling in csv files off of github and then merging to one big file
  
  #download CTD data from EDI
  historic_file  <- "https://pasta.lternet.edu/package/data/eml/edi/200/13/27ceda6bc7fdec2e7d79a6e4fe16ffdf" 
  infile1 <- tempfile()
  try(download.file(historic_file,infile1,method="curl"))
  if (is.na(file.size(infile1))) download.file(inUrl1,infile1,method="auto")
  historic_df <- read_csv(infile1) |> filter(Site == 50, Reservoir == "FCR", Depth_m > 0)
  
  #select cols needed to generate targets
  #file1 <- file1 |> select()
  historic_df <- historic_df |> select(c(DateTime,Reservoir,Depth_m,DO_mgL))
  
  #combine current and historic ctd data
  #DO <- dplyr::bind_rows(current_df, historic_df) #use this once we get current data incorporated 
  DO <- dplyr::bind_rows(historic_df)
  
  #change reservoir site name
  DO$Reservoir <- "fcre"
  
  #change names so df matches targets format
  DO <- DO |> rename(datetime = DateTime,
                       site_id = Reservoir,
                       depth_m = Depth_m,
                       observation = DO_mgL) 
  
  #add variable column
  DO$variable <- "DO_mgL"
  
  #now calculate MOM binary
  MOM_binary <- DO |> group_by(datetime, site_id, variable) |>
    mutate(MOM_binary = ifelse(observation < 2 & depth_m >= 2 & depth_m <= 8, 1, 0)) |>
    summarise(MOM_binary = max(MOM_binary)) |> select(-variable)

  #rename columns to match targets file
  MOM_binary <- MOM_binary |>
    rename(observation = MOM_binary)
  
  MOM_binary$variable <- "MetalimneticOxygenMinimum_binary"
  
  #Depth is na bc full water column variable
  MOM_binary$depth_m <- NA
  
  # return dataframe formatted to match FLARE targets
  return(MOM_binary)
  
  }


