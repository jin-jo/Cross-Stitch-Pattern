library(imager)
library(tidyverse)
library(tidymodels)
library(sp)
library(scales)
library(cowplot)
#devtools::install_github("sharlagelfand/dmc")
library(dmc)


process_image <- function(image_file_name, k_list){
  
  ## process_image(image_file_name, k_list) computes 
  ## a clustering and augments the initial data 
  ## with the given cluster.
  ## 
  ## Input:
  ## - image_file_name: a PNG or JPEG image
  ## - k_list: the number of centres in the clustering
  ##
  ## Output:
  ## - A list of information derived from the k-means. 
  ##  The first element from the list indicates the tidied clusters with 
  ##  their associated RGB values and their nearest DMC thread colour information. 
  ##  The second element from the list indicates the augmented data with the clusters.
  ##  The third element from the list indicates the original output of the kclust calls.
  ##  The fourth element from the list indicates the infomation of 
  ##  the total within sum of square. This will be used for the scree plot.
  ##  The last element from the list indicates the k_list.
  ##
  ## Example:
  ##  im <- imager::load.image("liza_minnelli_andy_warhol_collection.jpg")
  ##  cluster_info <- process_image(im, c(2,4,6))
  
  tidy_dat <- as.data.frame(image_file_name, wide = "c") %>% 
    rename(R = c.1, G = c.2, B = c.3)
  
  set.seed(523)
  
  information = rep(NA, length(n))
  
  k <- k_list
  
  for (value in k){ 
    kclust <- kmeans(select(tidy_dat, -x,-y), centers = value, nstart = 4) 
    
    information[value] <-  sum(kclust$withinss)
    
    centres <- tidy(kclust)
    centres <- centres %>% mutate(col = rgb(R,G,B))
    centres <- centres %>% mutate(colour = map(centres$col, ~dmc(.x)))
  }
  
  tidy_dat2 <- augment(kclust, tidy_dat) %>% rename(cluster = .cluster)
  
  k_info <- tibble(k = rep(1:length(information)), wit = information)
  
  return(list(centres, tidy_dat2, kclust, k_info, k))
}

# NOTE:
# General function: assign function output to object
# cluster_info <- process_image(image_file_name, k_list)


scree_plot <- function(val){
  
  ## scree_plot(val) produces and plots a scree plot 
  ## for determining k in k-means.
  ##
  ## Input:
  ## - val: The output of process_image function
  ##
  ## Output:
  ## - A scree plot where x-axis indicates the cluster number and 
  ##  y-axis indicates the total within sum of square.
  ##
  ## Example:
  ##    im <- imager::load.image("liza_minnelli_andy_warhol_collection.jpg")
  ##    cluster_info <- process_image(im, c(2,4,6))
  ##    scree_plot(cluster_info)
  
  clustering <- na.omit(val[[4]])
  
  ggplot(clustering, aes(k, wit)) + 
    labs(x = "k", y = "Total within sum of square") +
    geom_point() + 
    geom_line()
}


colour_strips <- function(val){
  
  ## colour_strips(val) produces colour strips with the DMC colour closest to the 
  ## cluster centre colour. 
  ##
  ## Input:
  ## - val: The output of process_image function
  ##
  ## Output:
  ## - A plot or strips with colours and names of the colours using hex strings.
  ##    Note that the colours are based on DMC information, but names of the colours
  ##    use hex strings which are based on the RGB information.
  ##
  ## Example:
  ##    im <- imager::load.image("liza_minnelli_andy_warhol_collection.jpg")
  ##    cluster_info <- process_image(im, 6)
  ##    colour_strips(cluster_info)
  
  # k_nums indicates k_list in process_image
  k_nums <- val[[5]]
  
  if(length(k_nums) == 1){
    show_col(val[[1]]$col)
    text <- paste0("k = ", k_nums)
    title(text, adj = 1)
    
  } else{
    for(k_num in k_nums){
      new <-val[[1]]$col
      show_col(new[1:k_num])
      text <- paste0("k = ", k_num)
      title(text, adj = 1)
    }
  }
}


change_resolution <- function(image_df, x_size)
{
  ## change_resolution(image_df, x_size) subsamples an image to produce
  ## a lower resolution image. Any non-coordinate columns in the data
  ## frame are summarized with their most common value in the larger
  ## grid cell.
  ##
  ## Input:
  ## - image_df: A data frame in wide format. The x-coordinate column MUST
  ##             be named 'x' and the y-coordinate column MUST be named 'y'.
  ##             Further columns have no naming restrictions.
  ## - x_size:   The number of cells in the x-direction. The number of cells
  ##             in the vertical direction will be computed to maintain the 
  ##             perspective. There is no guarantee that the exact number
  ##             of cells in the x-direction is x_size
  ##
  ## Output:
  ## - A data frame with the same column names as image_df, but with fewer 
  ##   entries that corresponds to the reduced resolution image.
  ##
  ## Example:
  ##   library(imager)
  ##   library(dplyr)
  ##   fpath <- system.file('extdata/Leonardo_Birds.jpg',package='imager') 
  ##   im <- load.image(fpath)
  ##   im_dat<- as.data.frame(im,wide = "c") %>% rename(R = c.1, G = c.2, B = c.3) %>%
  ##            select(x,y,R,G,B)
  ##   agg_image <- change_resolution(im_dat, 50)
  
  if(!require(sp)) {
    stop("The sp packages must be installed. Run install.packages(\"sp\") and then try again.")
  }
  if(!require(dplyr)) {
    stop("The dplyr packages must be installed. Run install.packages(\"dplyr\") and then try again.")
  }
  
  sp_dat <- image_df 
  gridded(sp_dat) = ~x+y
  
  persp = (gridparameters(sp_dat)$cells.dim[2]/gridparameters(sp_dat)$cells.dim[1])
  y_size = floor(x_size*persp)
  orig_x_size = gridparameters(sp_dat)$cells.dim[1]
  orig_y_size = gridparameters(sp_dat)$cells.dim[2]
  
  x_res = ceiling(orig_x_size/x_size)
  y_res = ceiling(orig_y_size/y_size)
  
  gt = GridTopology(c(0.5,0.5), c(x_res, y_res),
                    c(floor(orig_x_size/x_res), floor(orig_y_size/y_res)))
  SG = SpatialGrid(gt)
  agg = aggregate(sp_dat, SG, function(x) names(which.max(table(x)))[1] )
  agg@grid@cellsize <- c(1,1)
  df <- agg %>% as.data.frame %>% rename(x = s1, y = s2)  %>% select(colnames(image_df))
  
  return(df)
}


make_pattern <- function(val, 
                         k, 
                         x_size = 50, 
                         black_white = FALSE,
                         background_colour = NULL) {
  
  ## make_pattern(val, k, x_size, balck_white = FALSE, background_colour = NULL)
  ## produces a cross-stitch pattern that can be followed, complete with a legend 
  ## that has thread colour, and a guide grid. 
  ##
  ## Input:
  ## - val: The output of process_image function
  ## - k: The chosen cluster size
  ## - x_size: The (approximate) total number of possible stitches in the 
  ##          horizontal direction
  ## - black_white: (logical) Print the pattern in black and white (TRUE) or
  ##          colour (FALSE, default)
  ## - background_colour: The colour of the backgroudn, which should not be stitched 
  ##                    in the pattern
  ##
  ## Output:
  ## - A plot of cross-stitch pattern with a legend that has thread colour, 
  ##  and a guide grid
  ##
  ## Example:
  ##    im <- imager::load.image("liza_minnelli_andy_warhol_collection.jpg")
  ##    cluster_info <- process_image(im, c(2:10))
  ##    make_pattern(cluster_info, k = 6, x_size)
  ##    make_pattern(cluster_info, k = 6, x_size = 25, black_white = TRUE)
  ##    make_pattern(cluster_info, k = 6, x_size = 25, background_colour = "#1E1108")
  
  img_resized <- change_resolution(val[[2]], x_size = x_size)
  
  # Creating the colour pallette with colour names
  cluster = 1:k
  dmc = unlist(map(val[[1]]$colour[1:k], 1))
  dmc_name = unlist(map(val[[1]]$colour[1:k], 2))
  hex = unlist(map(val[[1]]$colour[1:k], 3))
  dmc_name_full = paste0(unlist(map(val[[1]]$colour[1:k], 2)), " (",
                         unlist(map(val[[1]]$colour[1:k], 1)), ")")
  
  color_pal <- bind_cols(col1 = cluster, col2 =  dmc, col3 = dmc_name, col4 = hex, col5 = dmc_name_full)
  
  if(is.null(background_colour)){
    if(black_white == FALSE) {
      ggplot(img_resized, aes(x = x, y = y, group = cluster)) +
        geom_point(aes(shape = cluster, color = cluster)) +
        scale_shape_manual(name = "DMC Colour", values=c(0:(k-1)),  labels = color_pal$col5[1:k]) +
        scale_color_manual(name = "DMC Colour", values=color_pal$col4, labels = color_pal$col5) + 
        theme_linedraw() +
        theme(panel.background = element_rect(fill = background_colour)) +
        theme(panel.grid.major = element_line(size = 1, linetype = "solid", color = "black")) +
        scale_y_reverse() +
        theme(axis.title.x = element_blank(),
              axis.title.y = element_blank(),
              axis.text.x = element_blank(),
              axis.text.y = element_blank())
      
    } else {
      ggplot(img_resized, aes(x = x, y = y, group = cluster, shape = cluster)) +
        geom_point() +
        scale_shape_manual(name = "DMC Colour", values= c(0:(k-1)), labels = color_pal$col5[1:k]) +
        scale_fill_grey() + 
        theme_linedraw() +
        theme(panel.background = element_rect(fill = background_colour)) +
        theme(panel.grid.major = element_line(size = 1, linetype = "solid", color = "black")) +
        scale_y_reverse() +
        theme(axis.title.x = element_blank(),
              axis.title.y = element_blank(),
              axis.text.x = element_blank(),
              axis.text.y = element_blank())
    }
  } else{
    if(black_white == FALSE) {
      
      color_pal_new <- color_pal %>% filter(col4 != background_colour)
      
      ggplot(img_resized, aes(x = x, y = y, group = cluster)) +
        geom_point(aes(shape = cluster, color = cluster)) +
        scale_shape_manual(name = "DMC Colour", 
                           values=c(0:(k-1)),
                           labels = color_pal_new$col5[1:k]) +
        scale_color_manual(name = "DMC Colour", values=color_pal_new$col4, labels = color_pal_new$col5) + 
        theme_linedraw() +
        theme(panel.background = element_rect(fill = background_colour)) +
        theme(panel.grid.major = element_line(size = 1, linetype = "solid", color = "black")) +
        scale_y_reverse() +
        theme(axis.title.x = element_blank(),
              axis.title.y = element_blank(),
              axis.text.x = element_blank(),
              axis.text.y = element_blank())
      
    } else {
      
      color_pal_new <- color_pal %>% filter(col4 != background_colour)
      
      ggplot(img_resized, aes(x = x, y = y, group = cluster)) +
        geom_point(aes(shape= cluster)) +
        scale_shape_manual(name = "DMC Colour", 
                           values= c(0:(k-1)), 
                           labels = color_pal_new$col5[1:k]) +
        scale_fill_grey() + 
        theme_linedraw() +
        theme(panel.background = element_rect(fill = background_colour)) +
        theme(panel.grid.major = element_line(size = 1, linetype = "solid", color = "black")) +
        scale_y_reverse() +
        theme(axis.title.x = element_blank(),
              axis.title.y = element_blank(),
              axis.text.x = element_blank(),
              axis.text.y = element_blank())
    }
  }
}

