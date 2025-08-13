# Regressions for the "Public transport in the 15-minutes city" paper - April 2025

rm(list=ls())

# Import libraries
library(ggplot2)
library(ggstance)
library(stargazer)
library(dplyr)
library(standardize)
library(mosaic)


library(gridExtra)
library(cowplot)


# 1. Folder and data
# setwd("g:/Saját meghajtó/Public transport in the 15-minutes city") # I work in a Google Drive folder shard with the group.
setwd("/home/gergo/NETI/code/stop_accessibility/src/regression")
  bp=read.table("./budapest/bp_socioecon_merged5.csv", header = T, sep=",")
#  helsinki=read.table("./helsinki/helsinki_socioecon_merged2.csv", header = T, sep=",")
  madrid=read.table("./madrid/madrid_socioecon_merged2.csv", header = T, sep=",")

  helsinki=read.table("./helsinki/helsinki_socioecon_merged4.csv", header = T, sep=",")

ls(bp)
ls(madrid)
ls(helsinki)

# 2. Generate Access variables

bp <- bp %>%
  mutate(
    cultural_institutions_multimod_d = as.integer(cultural_institutions_multimodal > 0),
    drugstores_multimodal_d = as.integer(drugstores_multimodal > 0),
    groceries_multimodal_d = as.integer(groceries_multimodal > 0),
    healthcare_multimodal_d = as.integer(healthcare_multimodal > 0),
    parks_multimodal_d = as.integer(parks_multimodal > 0),
    religious_organ_multimod_d = as.integer(religious_organizations_multimodal > 0),
    restaurants_multimodal_d = as.integer(restaurants_multimodal > 0),
    schools_multimodal_d = as.integer(schools_multimodal > 0),
    services_multimodal_d = as.integer(services_multimodal > 0),

    cultural_institutions_walk15_d = as.integer(cultural_institutions_walk15 > 0),
    drugstores_walk15_d = as.integer(drugstores_walk15 > 0),
    groceries_walk15_d = as.integer(groceries_walk15 > 0),
    healthcare_walk15_d = as.integer(healthcare_walk15 > 0),
    parks_walk15_d = as.integer(parks_walk15 > 0),
    religious_organizations_walk15_d = as.integer(religious_organizations_walk15 > 0),
    restaurants_walk15_d = as.integer(restaurants_walk15 > 0),
    schools_walk15_d = as.integer(schools_walk15 > 0),
    services_walk15_d = as.integer(services_walk15 > 0),

    multimod_sum = cultural_institutions_multimod_d + drugstores_multimodal_d +
      groceries_multimodal_d + healthcare_multimodal_d +
      parks_multimodal_d + religious_organ_multimod_d +
      restaurants_multimodal_d + schools_multimodal_d +
      services_multimodal_d,

    walk_sum = cultural_institutions_walk15_d + drugstores_walk15_d +
      groceries_walk15_d + healthcare_walk15_d +
      parks_walk15_d + religious_organizations_walk15_d +
      restaurants_walk15_d + schools_walk15_d +
      services_walk15_d
  )

helsinki <- helsinki %>%
  mutate(
    cultural_institutions_multimod_d = as.integer(cultural_institutions_multimodal > 0),
    drugstores_multimodal_d = as.integer(drugstores_multimodal > 0),
    groceries_multimodal_d = as.integer(groceries_multimodal > 0),
    healthcare_multimodal_d = as.integer(healthcare_multimodal > 0),
    parks_multimodal_d = as.integer(parks_multimodal > 0),
    religious_organ_multimod_d = as.integer(religious_organizations_multimodal > 0),
    restaurants_multimodal_d = as.integer(restaurants_multimodal > 0),
    schools_multimodal_d = as.integer(schools_multimodal > 0),
    services_multimodal_d = as.integer(services_multimodal > 0),

    cultural_institutions_walk15_d = as.integer(cultural_institutions_walk15 > 0),
    drugstores_walk15_d = as.integer(drugstores_walk15 > 0),
    groceries_walk15_d = as.integer(groceries_walk15 > 0),
    healthcare_walk15_d = as.integer(healthcare_walk15 > 0),
    parks_walk15_d = as.integer(parks_walk15 > 0),
    religious_organizations_walk15_d = as.integer(religious_organizations_walk15 > 0),
    restaurants_walk15_d = as.integer(restaurants_walk15 > 0),
    schools_walk15_d = as.integer(schools_walk15 > 0),
    services_walk15_d = as.integer(services_walk15 > 0),

    multimod_sum = cultural_institutions_multimod_d + drugstores_multimodal_d +
      groceries_multimodal_d + healthcare_multimodal_d +
      parks_multimodal_d + religious_organ_multimod_d +
      restaurants_multimodal_d + schools_multimodal_d +
      services_multimodal_d,

    walk_sum = cultural_institutions_walk15_d + drugstores_walk15_d +
      groceries_walk15_d + healthcare_walk15_d +
      parks_walk15_d + religious_organizations_walk15_d +
      restaurants_walk15_d + schools_walk15_d +
      services_walk15_d
  )

madrid <- madrid %>%
  mutate(
    cultural_institutions_multimod_d = as.integer(cultural_institutions_multimodal > 0),
    drugstores_multimodal_d = as.integer(drugstores_multimodal > 0),
    groceries_multimodal_d = as.integer(groceries_multimodal > 0),
    healthcare_multimodal_d = as.integer(healthcare_multimodal > 0),
    parks_multimodal_d = as.integer(parks_multimodal > 0),
    religious_organ_multimod_d = as.integer(religious_organizations_multimodal > 0),
    restaurants_multimodal_d = as.integer(restaurants_multimodal > 0),
    schools_multimodal_d = as.integer(schools_multimodal > 0),
    services_multimodal_d = as.integer(services_multimodal > 0),

    cultural_institutions_walk15_d = as.integer(cultural_institutions_walk15 > 0),
    drugstores_walk15_d = as.integer(drugstores_walk15 > 0),
    groceries_walk15_d = as.integer(groceries_walk15 > 0),
    healthcare_walk15_d = as.integer(healthcare_walk15 > 0),
    parks_walk15_d = as.integer(parks_walk15 > 0),
    religious_organizations_walk15_d = as.integer(religious_organizations_walk15 > 0),
    restaurants_walk15_d = as.integer(restaurants_walk15 > 0),
    schools_walk15_d = as.integer(schools_walk15 > 0),
    services_walk15_d = as.integer(services_walk15 > 0),

    multimod_sum = cultural_institutions_multimod_d + drugstores_multimodal_d +
      groceries_multimodal_d + healthcare_multimodal_d +
      parks_multimodal_d + religious_organ_multimod_d +
      restaurants_multimodal_d + schools_multimodal_d +
      services_multimodal_d,

    walk_sum = cultural_institutions_walk15_d + drugstores_walk15_d +
      groceries_walk15_d + healthcare_walk15_d +
      parks_walk15_d + religious_organizations_walk15_d +
      restaurants_walk15_d + schools_walk15_d +
      services_walk15_d
  )


# 3. Distributions
plot(bp$gini_walk15, bp$gini_multimodal)
  plot(bp$gini_house_walk15, bp$gini_house_multimodal)
  plot(madrid$weighted_gini_walk, madrid$weighted_gini_multi)
  plot(helsinki$weighted_gini_walk, helsinki$weighted_gini_multi)

hist(bp$gini_multimodal-bp$gini_walk15)
  hist(bp$gini_house_multimodal-bp$gini_house_walk15)
  hist(madrid$weighted_gini_multi-madrid$weighted_gini_walk)
  hist(helsinki$weighted_gini_multi-helsinki$weighted_gini_walk)

plot(helsinki$area, helsinki$area_difference)

plot(log(bp$distance_betweenness), bp$ellipticity)
  plot(log(madrid$distance_betweenness), madrid$ellipticity)
  plot(log(helsinki$distance_betweenness), helsinki$ellipticity)

plot(bp$stop_lon[bp$distance_betweenness>quantile(bp$distance_betweenness,0.25)],
     bp$stop_lat[bp$distance_betweenness>quantile(bp$distance_betweenness,0.25)])

plot(madrid$stop_lon[madrid$distance_betweenness>quantile(madrid$distance_betweenness,0.25)],
     madrid$stop_lat[madrid$distance_betweenness>quantile(madrid$distance_betweenness,0.25)])

plot(helsinki$stop_lon[helsinki$distance_betweenness>quantile(helsinki$distance_betweenness,0.25)],
     helsinki$stop_lat[helsinki$distance_betweenness>quantile(helsinki$distance_betweenness,0.25)])


# 4. regressions

# 4.1 Coefficient plots into Main Taxt

# Main regressions without interactions

bp$gini_diff=bp$gini_multimodal-bp$gini_walk15
bp$gini_diff_house=bp$gini_house_multimodal-bp$gini_house_walk15

helsinki$gini_diff=helsinki$weighted_gini_multi-helsinki$weighted_gini_walk
madrid$gini_diff=madrid$weighted_gini_multi-madrid$weighted_gini_walk


bp$access_diff=bp$multimod_sum-bp$walk_sum
madrid$access_diff=madrid$multimod_sum-madrid$walk_sum
helsinki$access_diff=helsinki$multimod_sum-helsinki$walk_sum
write.csv(bp, "bp.csv", row.names=TRUE)
write.csv(madrid, "madrid.csv", row.names=TRUE)
write.csv(helsinki, "helsinki.csv", row.names=TRUE)

bp1_noint=lm(gini_diff ~
               #area+
               gini_walk15+
               area_difference+
               ellipticity+
               distance_betweenness,
             data=bp)
sink("lm.txt")
summary(bp1_noint)
sink()

bp2_noint=lm(bp$gini_diff_house ~
               #area+
               gini_walk15+
               area_difference+
               ellipticity+
               distance_betweenness,
             data=bp)
#summary(bp2_noint)

helsinki1_noint=lm(gini_diff ~
                     #area+
                     weighted_gini_walk+
                     area_difference+
                     ellipticity+
                     distance_betweenness,
                   data=helsinki)
#summary(helsinki1_noint)


madrid1_noint=lm(gini_diff ~
                   #area+
                   weighted_gini_walk+
                   area_difference+
                   ellipticity+
                   distance_betweenness,
                 data=madrid)
#summary(madrid1_noint)

bp1a_noint=lm(access_diff ~
                walk_sum+
                #area+
                area_difference+
                ellipticity+
                distance_betweenness,
              data=bp)
#summary(bp1a_noint)

helsinki1a_noint=lm(access_diff ~
                      walk_sum+
                      #area+
                      area_difference+
                      ellipticity+
                      distance_betweenness,
                    data=helsinki)
#summary(helsinki1a_noint)

madrid1a_noint=lm(access_diff ~
                    walk_sum+
                    #area+
                    area_difference+
                    ellipticity+
                    distance_betweenness,
                  data=madrid)
#summary(madrid1a_noint)

h1a = helsinki1a_noint
m1a = madrid1a_noint
h1 = helsinki1_noint
m1 = madrid1_noint
b1a = bp1a_noint
b1 = bp1_noint
b2 = bp2_noint

stargazer(h1a, m1a, b1a, h1, m1, b2, b1,
          type="latex",
          style="aer",
          column.labels = c("Helsinki - Access", "Madrid - Access",
                            "BP - Access",
                            "Helsinki - Gini",
                            "Madrid - Gini",
                            "BP residential - Gini",
                            "BP experienced - Gini"),
          dep.var.labels.include = F,
          out="SI_Reg_1_noint.tex")


# Regression decomposition without interaction term

bp_avg_price=read.table("./budapest/stop_property_price.csv", header = T, sep=",")
bp=merge(bp, bp_avg_price, by="stop_id", all.x=T, all.y=F)
ls(bp_avg_price)


bp1_noint_l=lm(gini_diff ~
                 gini_walk15+
                 area_difference+
                 ellipticity+
                 distance_betweenness,
               data=bp[bp$arpu_low_ratio_walk15>
                         median(bp$arpu_low_ratio_walk15),])

bp1_noint_h=lm(gini_diff ~
                 gini_walk15+
                 area_difference+
                 ellipticity+
                 distance_betweenness,
               data=bp[bp$arpu_low_ratio_walk15<
                         median(bp$arpu_low_ratio_walk15),])

bp2_noint_l=lm(gini_diff_house ~
                 gini_walk15+
                 area_difference+
                 ellipticity+
                 distance_betweenness,
               data=bp[bp$mean_price<
                         median(bp$mean_price, na.rm = T),])

bp2_noint_h=lm(gini_diff_house ~
                 gini_walk15+
                 area_difference+
                 ellipticity+
                 distance_betweenness,
               data=bp[bp$mean_price>
                         median(bp$mean_price, na.rm = T),])

helsinki1_noint_l=lm(gini_diff ~
                       weighted_gini_walk+
                       area_difference+
                       ellipticity+
                       distance_betweenness,
                     data=helsinki[helsinki$weighted_med_inc_walk<
                                     median(helsinki$weighted_med_inc_walk),])

helsinki1_noint_h=lm(gini_diff ~
                       #area+
                       weighted_gini_walk+
                       area_difference+
                       ellipticity+
                       distance_betweenness,
                     data=helsinki[helsinki$weighted_med_inc_walk>
                                     median(helsinki$weighted_med_inc_walk),])

madrid1_noint_l=lm(gini_diff ~
                     #area+
                     weighted_gini_walk+
                     area_difference+
                     ellipticity+
                     distance_betweenness,
                   data=madrid[madrid$weighted_net_income_hh_walk<
                                 median(madrid$weighted_net_income_hh_walk),])

madrid1_noint_h=lm(gini_diff ~
                     #area+
                     weighted_gini_walk+
                     area_difference+
                     ellipticity+
                     distance_betweenness,
                   data=madrid[madrid$weighted_net_income_hh_walk>
                                 median(madrid$weighted_net_income_hh_walk),])

bp1a_noint_l=lm(access_diff ~
                  walk_sum+
                  #area+
                  area_difference+
                  ellipticity+
                  distance_betweenness,
                data=bp[bp$mean_price<
                          median(bp$mean_price, na.rm = T),])

bp1a_noint_h=lm(access_diff ~
                  walk_sum+
                  #area+
                  area_difference+
                  ellipticity+
                  distance_betweenness,
                data=bp[bp$mean_price>
                          median(bp$mean_price, na.rm = T),])

helsinki1a_noint_l=lm(access_diff ~
                        walk_sum+
                        #area+
                        area_difference+
                        ellipticity+
                        distance_betweenness,
                      data=helsinki[helsinki$weighted_med_inc_walk<
                                      median(helsinki$weighted_med_inc_walk),])

helsinki1a_noint_h=lm(access_diff ~
                        walk_sum+
                        #area+
                        area_difference+
                        ellipticity+
                        distance_betweenness,
                      data=helsinki[helsinki$weighted_med_inc_walk>
                                      median(helsinki$weighted_med_inc_walk),])

madrid1a_noint_l=lm(access_diff ~
                      walk_sum+
                      #area+
                      area_difference+
                      ellipticity+
                      distance_betweenness,
                    data=madrid[madrid$weighted_net_income_hh_walk<
                                  median(madrid$weighted_net_income_hh_walk),])

madrid1a_noint_h=lm(access_diff ~
                      walk_sum+
                      #area+
                      area_difference+
                      ellipticity+
                      distance_betweenness,
                    data=madrid[madrid$weighted_net_income_hh_walk>
                                  median(madrid$weighted_net_income_hh_walk),])


# Generate regression tables: no interactions decomposed by low-high socio-economic status

h1anil = helsinki1a_noint_l
m1anil = madrid1a_noint_l
b1anil = bp1a_noint_l
h1nil = helsinki1_noint_l
m1nil = madrid1_noint_l
b2nil = bp2_noint_l
b1nil = bp1_noint_l
stargazer(h1anil, m1anil, b1anil, h1nil, m1nil, b2nil, b1nil,
          type="latex",
          style="aer",
          column.labels = c("Helsinki - Access", "Madrid - Access",
                            "BP - Access",
                            "Helsinki - Gini",
                            "Madrid - Gini",
                            "BP residential - Gini",
                            "BP experienced - Gini"),
          dep.var.labels.include = F,
          out="SI_Reg_2_noint_low.tex")

h1anih = helsinki1a_noint_h
m1anih = madrid1a_noint_h
b1anih = bp1a_noint_h
h1nih = helsinki1_noint_h
m1nih = madrid1_noint_h
b2nih = bp2_noint_h
b1nih = bp1_noint_h

stargazer(h1anih, m1anih, b1anih, h1nih, m1nih, b2nih, b1nih,
          type="latex",
          style="aer",
          column.labels = c("Helsinki - Access", "Madrid - Access",
                            "BP - Access",
                            "Helsinki - Gini",
                            "Madrid - Gini",
                            "BP residential - Gini",
                            "BP experienced - Gini"),
          dep.var.labels.include = F,
          out="SI_Reg_3_noint_high.tex")



# Generate decomposed coeff-plot in png

# List of model names (add or remove names as needed)
model_names <- c("helsinki1a_noint", "madrid1a_noint", "bp1a_noint",
                 "helsinki1_noint", "madrid1_noint", "bp2_noint", "bp1_noint",
                 "helsinki1a_noint_l", "madrid1a_noint_l", "bp1a_noint_l",
                 "helsinki1_noint_l", "madrid1_noint_l", "bp2_noint_l", "bp1_noint_l",
                 "helsinki1a_noint_h", "madrid1a_noint_h", "bp1a_noint_h",
                 "helsinki1_noint_h", "madrid1_noint_h", "bp2_noint_h", "bp1_noint_h")

# Function to create intercept and ellipticity data frames
extract_coeffs <- function(model_name) {
  t <- summary(get(model_name))$coefficients
  assign(paste0("int_", model_name),
         data.frame(Variable = "Intercept", Coefficient = t[1,1], SE = t[1,2]),
         envir = .GlobalEnv)
  assign(paste0("ellip_", model_name),
         data.frame(Variable = "Ellipticity", Coefficient = t[4,1], SE = t[4,2]),
         envir = .GlobalEnv)
}

# Apply function to each model
lapply(model_names, extract_coeffs)


# Access
allModelFrame_a <- data.frame(rbind(
  int_helsinki1a_noint, int_madrid1a_noint, int_bp1a_noint,
  int_helsinki1a_noint_l, int_madrid1a_noint_l, int_bp1a_noint_l,
  int_helsinki1a_noint_h, int_madrid1a_noint_h, int_bp1a_noint_h,
  ellip_helsinki1a_noint, ellip_madrid1a_noint, ellip_bp1a_noint,
  ellip_helsinki1a_noint_l, ellip_madrid1a_noint_l, ellip_bp1a_noint_l,
  ellip_helsinki1a_noint_h, ellip_madrid1a_noint_h, ellip_bp1a_noint_h))


allModelFrame_a$col = "grey"
allModelFrame_a$col[c(4:6,13:15)] = "darkblue"  # low
allModelFrame_a$col[c(7:9,16:18)] = "orange" # high
allModelFrame_a$fcol <- factor(allModelFrame_a$col)
allModelFrame_a$ypos=c(15, 15, 15,
                       13, 13, 13,
                       11, 11, 11,
                       7, 7, 7,
                       5, 5, 5,
                       3,3,3
)
allModelFrame_a$shape=16


# Define index subsets for each city
helsinki_idx <- c(1,4,7,10,13,16)
madrid_idx   <- c(2,5,8,11,14,17)
budapest_idx <- c(3,6,9,12,15,18)

# Plot function with y-axis labels and vertical text (for Helsinki)
plot_city_with_y <- function(idx, city_name) {
  ggplot(allModelFrame_a[idx,]) +
    geom_vline(xintercept = 0, linetype = "solid", size = 4, colour = "gray80") +
    geom_hline(yintercept = 9, linetype = "dotted", size = 4, colour = "gray80") +
    geom_point(aes(x = Coefficient, y = ypos, colour = fcol), shape = 16, size = 12) +
    geom_linerangeh(aes(xmin = Coefficient - 1.96 * SE,
                        xmax = Coefficient + 1.96 * SE,
                        y = ypos,
                        colour = fcol), size = 3) +
    scale_colour_manual(values = c("grey" = "grey", "darkblue" = "darkblue", "orange" = "orange")) +
    scale_y_continuous(labels = c("Intercept", "Ellipticity"), breaks = c(13, 5)) +
    labs(title = city_name, x = NULL, y = NULL) +
    theme_bw() +
    theme(panel.grid = element_blank(),
          plot.title = element_text(hjust = 0.5, size = 28),
          axis.text.x = element_text(size = 24),
          axis.text.y = element_text(size = 24, angle = 90, hjust = 0.5),
          legend.position = "none")
}


# Plot function without y-axis labels (Madrid, Budapest)
plot_city_noy <- function(idx, city_name) {
  ggplot(allModelFrame_a[idx,]) +
    geom_vline(xintercept = 0, linetype = "solid", size = 4, colour = "gray80") +
    geom_hline(yintercept = 9, linetype = "dotted", size = 4, colour = "gray80") +
    geom_point(aes(x = Coefficient, y = ypos, colour = fcol), shape = 16, size = 12) +
    geom_linerangeh(aes(xmin = Coefficient - 1.96 * SE,
                        xmax = Coefficient + 1.96 * SE,
                        y = ypos,
                        colour = fcol), size = 3) +
    scale_colour_manual(values = c("grey" = "grey", "darkblue" = "darkblue", "orange" = "orange")) +
    scale_y_continuous(breaks = c(13, 5), labels = NULL) +
    labs(title = city_name, x = NULL, y = NULL) +
    theme_bw() +
    theme(panel.grid = element_blank(),
          plot.title = element_text(hjust = 0.5, size = 28),
          axis.text.x = element_text(size = 16),
          axis.text.y = element_blank(),
          axis.ticks.y = element_blank(),
          legend.position = "none")
}


# Generate the three city plots
plot_hel <- plot_city_with_y(helsinki_idx, "Helsinki")
plot_mad <- plot_city_noy(madrid_idx, "Madrid")
plot_bud <- plot_city_noy(budapest_idx, "Budapest")

# Combine plots
final_plot <- cowplot::plot_grid(plot_hel, plot_mad, plot_bud, nrow = 1, align = "h")

# Save to file
ggsave("Main_coeff_combined_plot_access_noint.png", plot = final_plot, width = 16, height = 8)



# Gini
allModelFrame_g <- data.frame(rbind(
  int_helsinki1_noint, int_madrid1_noint, int_bp2_noint, int_bp1_noint,
  int_helsinki1_noint_l, int_madrid1_noint_l, int_bp2_noint_l, int_bp1_noint_l,
  int_helsinki1_noint_h, int_madrid1_noint_h, int_bp2_noint_h, int_bp1_noint_h,
  ellip_helsinki1_noint, ellip_madrid1_noint, ellip_bp2_noint, ellip_bp1_noint,
  ellip_helsinki1_noint_l, ellip_madrid1_noint_l, ellip_bp2_noint_l, ellip_bp1_noint_l,
  ellip_helsinki1_noint_h, ellip_madrid1_noint_h, ellip_bp2_noint_h, ellip_bp1_noint_h))


# Add metadata to Gini model frame
allModelFrame_g$col <- "grey"
allModelFrame_g$col[c(5:8,17:20)] <- "darkblue"  # low
allModelFrame_g$col[c(9:12,21:24)] <- "orange"   # high
allModelFrame_g$fcol <- factor(allModelFrame_g$col)

# Matching Access layout
allModelFrame_g$ypos <- c(
  15, 15, 15, 15,
  13, 13, 13, 13,
  11, 11, 11, 11,
  7, 7, 7, 7,
  5, 5, 5, 5,
  3, 3, 3, 3
)
allModelFrame_g$shape <- 16

# Define index subsets (4 cities: helsinki, madrid, bp2, bp1)
helsinki_idx_g <- c(1, 5, 9, 13, 17, 21)
madrid_idx_g   <- c(2, 6,10, 14, 18, 22)
bp2_idx_g      <- c(3, 7,11, 15, 19, 23)
bp1_idx_g      <- c(4, 8,12, 16, 20, 24)

# Updated plot functions for Gini data
plot_city_with_y_gini <- function(idx, city_name) {
  ggplot(allModelFrame_g[idx,]) +
    geom_vline(xintercept = 0, linetype = "solid", size = 4, colour = "gray80") +
    geom_hline(yintercept = 9, linetype = "dotted", size = 4, colour = "gray80") +
    geom_point(aes(x = Coefficient, y = ypos, colour = fcol), shape = 16, size = 12) +
    geom_linerangeh(aes(xmin = Coefficient - 1.96 * SE,
                        xmax = Coefficient + 1.96 * SE,
                        y = ypos,
                        colour = fcol), size = 3) +
    scale_colour_manual(values = c("grey" = "grey", "darkblue" = "darkblue", "orange" = "orange")) +
    scale_y_continuous(labels = c("Intercept", "Ellipticity"), breaks = c(13, 5)) +
    labs(title = city_name, x = NULL, y = NULL) +
    theme_bw() +
    theme(panel.grid = element_blank(),
          plot.title = element_text(hjust = 0.5, size = 28),
          axis.text.x = element_text(size = 24),
          axis.text.y = element_text(size = 24, angle = 90, hjust = 0.5),
          legend.position = "none")
}

plot_city_noy_gini <- function(idx, city_name) {
  ggplot(allModelFrame_g[idx,]) +
    geom_vline(xintercept = 0, linetype = "solid", size = 4, colour = "gray80") +
    geom_hline(yintercept = 9, linetype = "dotted", size = 4, colour = "gray80") +
    geom_point(aes(x = Coefficient, y = ypos, colour = fcol), shape = 16, size = 12) +
    geom_linerangeh(aes(xmin = Coefficient - 1.96 * SE,
                        xmax = Coefficient + 1.96 * SE,
                        y = ypos,
                        colour = fcol), size = 3) +
    scale_colour_manual(values = c("grey" = "grey", "darkblue" = "darkblue", "orange" = "orange")) +
    scale_y_continuous(breaks = c(13, 5), labels = NULL) +
    labs(title = city_name, x = NULL, y = NULL) +
    theme_bw() +
    theme(panel.grid = element_blank(),
          plot.title = element_text(hjust = 0.5, size = 28),
          axis.text.x = element_text(size = 16),
          axis.text.y = element_blank(),
          axis.ticks.y = element_blank(),
          legend.position = "none")
}

# Generate the four city plots
plot_hel_g <- plot_city_with_y_gini(helsinki_idx_g, "Helsinki")
plot_mad_g <- plot_city_noy_gini(madrid_idx_g, "Madrid")
plot_bp2_g <- plot_city_noy_gini(bp2_idx_g, "Budapest (residential)")
plot_bp1_g <- plot_city_noy_gini(bp1_idx_g, "Budapest (experienced)")

# Combine plots
final_plot_gini <- cowplot::plot_grid(plot_hel_g, plot_mad_g, plot_bp2_g, plot_bp1_g, nrow = 1, align = "h")

# Save to file
ggsave("Main_coeff_combined_plot_gini_noint.png", plot = final_plot_gini, width = 20, height = 8)


# Legend

library(ggplot2)

# Create dummy data for the legend plot
legend_data <- data.frame(
  Label = factor(c("All observations", "Low socio-economic status", "High socio-economic status"),
                 levels = c("All observations", "Low socio-economic status", "High socio-economic status")),
  ypos = c(3, 2, 1),
  Coefficient = c(0.2, 0.2, 0.2),
  SE = c(0.02, 0.02, 0.02),
  fcol = factor(c("grey", "darkblue", "orange"),
                levels = c("grey", "darkblue", "orange"))
)

# Plot
legend_plot <- ggplot(legend_data) +
  geom_point(aes(x = Coefficient, y = ypos, colour = fcol), shape = 16, size = 10) +
  geom_linerangeh(aes(xmin = Coefficient - 2*SE,
                      xmax = Coefficient + 2*SE,
                      y = ypos,
                      colour = fcol), size = 2) +
  geom_text(aes(x = Coefficient + 0.05, y = ypos, label = Label), hjust = 0, size = 6) +
  scale_colour_manual(values = c("grey" = "grey", "darkblue" = "darkblue", "orange" = "orange")) +
  xlim(0.1, 1.0) +  # adjust this based on label length and position
  ylim(0, 4) +  # adjust this based on label length and position
  theme_void() +
  theme(legend.position = "none")

ggsave("Main_custom_legend_plot.png", plot = legend_plot, width = 8, height = 2.5)


# 4.2 Regressions with interactions into SI


bp1=lm(gini_multimodal-gini_walk15 ~
        #area+
        gini_walk15+
         area_difference*ellipticity+
         distance_betweenness*ellipticity,
        data=bp)
#summary(bp1)


bp2=lm(gini_house_multimodal-gini_house_walk15 ~
        #area+
        gini_walk15+
         area_difference*ellipticity+
         distance_betweenness*ellipticity,
        data=bp)
#summary(bp2)

helsinki1=lm(weighted_gini_multi-weighted_gini_walk ~
        #area+
        weighted_gini_walk+
          area_difference*ellipticity+
          distance_betweenness*ellipticity,
        data=helsinki)
#summary(helsinki1)

madrid1=lm(weighted_gini_multi-weighted_gini_walk ~
        #area+
        weighted_gini_walk+
          area_difference*ellipticity+
          distance_betweenness*ellipticity,
        data=madrid)
#summary(madrid1)


# 4.2 Access


bp1a=lm(multimod_sum-walk_sum ~
          walk_sum+
          #area+
         area_difference*ellipticity+
         distance_betweenness*ellipticity,
       data=bp)
#summary(bp1a)

helsinki1a=lm(multimod_sum-walk_sum ~
                walk_sum+
                #area+
                area_difference*ellipticity+
                distance_betweenness*ellipticity,
             data=helsinki)
#summary(helsinki1a)

madrid1a=lm(multimod_sum-walk_sum ~
              walk_sum+
              #area+
              area_difference*ellipticity+
              distance_betweenness*ellipticity,
           data=madrid)
#summary(helsinki1a)


# Write regression table

stargazer(helsinki1a, madrid1a, bp1a,helsinki1, madrid1, bp2, bp1,
          type="latex",
          style="aer",
          column.labels = c("Helsinki - Access", "Madrid - Access",
                            "BP - Access",
                            "Helsinki - Gini", "Madrid - Gini",
                            "BP residential - Gini",
                            "BP experienced - Gini"),
          dep.var.labels.include = F,
          out="SI_Reg_4.tex")

# 4.3 Standardized regressions with interactions

bp <- bp %>%
  mutate(
    gini_diff_s = scale(gini_diff),
    gini_walk15_s = scale(gini_walk15),
    area_difference_s = scale(area_difference),
    ellipticity_s = scale(ellipticity),
    distance_betweenness_s = scale(distance_betweenness),
    gini_diff_house_s = scale(gini_diff_house),
    access_diff_s = scale(access_diff),
    walk_sum_s = scale(walk_sum)
  )

madrid <- madrid %>%
  mutate(
    gini_diff_s = scale(gini_diff),
    weighted_gini_walk_s = scale(weighted_gini_walk),
    area_difference_s = scale(area_difference),
    ellipticity_s = scale(ellipticity),
    distance_betweenness_s = scale(distance_betweenness),
    access_diff_s = scale(access_diff),
    walk_sum_s = scale(walk_sum)
  )


helsinki <- helsinki %>%
  mutate(
    gini_diff_s = scale(gini_diff),
    weighted_gini_walk_s = scale(weighted_gini_walk),
    area_difference_s = scale(area_difference),
    ellipticity_s = scale(ellipticity),
    distance_betweenness_s = scale(distance_betweenness),
    access_diff_s = scale(access_diff),
    walk_sum_s = scale(walk_sum)
  )


bp1_s=lm(gini_diff_s ~
         gini_walk15_s+
         area_difference_s +
         ellipticity_s+
         distance_betweenness_s,
       data=bp)


bp2_s=lm(gini_diff_house_s ~
         gini_walk15_s+
           area_difference_s +
           ellipticity_s+
           distance_betweenness_s,
       data=bp)

helsinki1_s=lm(gini_diff_s ~
         weighted_gini_walk_s+
           area_difference_s +
           ellipticity_s+
           distance_betweenness_s,
       data=helsinki)

madrid1_s=lm(gini_diff_s ~
         weighted_gini_walk_s+
           area_difference_s +
           ellipticity_s+
           distance_betweenness_s,
       data=madrid)

bp1a_s=lm(access_diff_s ~
          walk_sum_s+
            area_difference_s +
            ellipticity_s+
            distance_betweenness_s,
        data=bp)

helsinki1a_s=lm(access_diff_s ~
          walk_sum_s+
            area_difference_s +
            ellipticity_s+
            distance_betweenness_s,
        data=helsinki)

madrid1a_s=lm(access_diff_s ~
          walk_sum_s+
            area_difference_s +
            ellipticity_s+
            distance_betweenness_s,
        data=madrid)

h1as = helsinki1a_s
m1as = madrid1a_s
b1as = bp1a_s
h1s = helsinki1_s
m1s = madrid1_s
b1s = bp1_s
b2s = bp2_s

stargazer(h1as, m1as, b1as,h1s, m1s, b2s, b1s,
          type="latex",
          style="aer",
          column.labels = c("Helsinki - Access", "Madrid - Access",
                            "BP - Access",
                            "Helsinki - Gini", "Madrid - Gini",
                            "BP residential - Gini",
                            "BP experienced - Gini"),
          dep.var.labels.include = F,
          out="SI_Reg_5_s.tex")

# 4.4 Interplots

library(interplot)
library(patchwork)


bp1i=lm(gini_multimodal-gini_walk15 ~
         gini_walk15+
         area_difference+
         distance_betweenness*ellipticity,
       data=bp)

bp2i=lm(gini_house_multimodal-gini_house_walk15 ~
         gini_walk15+
         area_difference+
         distance_betweenness*ellipticity,
       data=bp)

helsinki1i=lm(weighted_gini_multi-weighted_gini_walk ~
               weighted_gini_walk+
               area_difference+
               distance_betweenness*ellipticity,
             data=helsinki)

madrid1i=lm(weighted_gini_multi-weighted_gini_walk ~
             weighted_gini_walk+
             area_difference+
             distance_betweenness*ellipticity,
           data=madrid)

bp1ai=lm(multimod_sum-walk_sum ~
          walk_sum+
          area_difference+
          distance_betweenness*ellipticity,
        data=bp)

helsinki1ai=lm(multimod_sum-walk_sum ~
                walk_sum+
                area_difference+
                distance_betweenness*ellipticity,
              data=helsinki)

madrid1ai=lm(multimod_sum-walk_sum ~
              walk_sum+
              area_difference+
              distance_betweenness*ellipticity,
            data=madrid)


png("Main_interplot_bp1.png", width=1200, height=1200)
interplot(m = bp1i, var1 = "ellipticity", var2 = "distance_betweenness", hist=FALSE, point =T,
          steps = 30,
          esize = 2,
          ercolor = "black")+
  # Change the background
  # theme_bw() +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        panel.background = element_blank(), axis.line = element_line(colour = "black")) +
  # Add a horizontal line at y = 0
  geom_hline(yintercept = 0, linetype = "dashed") +
  # Add labels for X and Y axes
  xlab(expression(italic(D[i]))) +
  ylab(expression(paste('Coefficient of ', italic(E[i]), ' on ', italic(G[i]),' by levels of ', italic(D[i]))))+
  theme(axis.title=element_text(size=60),text = element_text(size=60))+
  theme(plot.title = element_text(face="bold")) +
  scale_x_continuous(breaks=c(0,2,4,6,8,10,12,14,16,18,20))
dev.off()

png("Main_interplot_bp2.png", width=1200, height=1200)
interplot(m = bp2i, var1 = "ellipticity", var2 = "distance_betweenness", hist=FALSE, point =T,
          steps = 30,
          esize = 2,
          ercolor = "black")+
  # Change the background
  # theme_bw() +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        panel.background = element_blank(), axis.line = element_line(colour = "black")) +
  # Add a horizontal line at y = 0
  geom_hline(yintercept = 0, linetype = "dashed") +
  # Add labels for X and Y axes
  xlab(expression(italic(D[i]))) +
  ylab(expression(paste('Coefficient of ', italic(E[i]), ' on ', italic(G[i]),' by levels of ', italic(D[i]))))+
  theme(axis.title=element_text(size=60),text = element_text(size=60))+
  theme(plot.title = element_text(face="bold")) +
  scale_x_continuous(breaks=c(0,2,4,6,8,10,12,14,16,18,20))
dev.off()


png("Main_interplot_helsinki1.png", width=1200, height=1200)
interplot(m = helsinki1i, var1 = "ellipticity", var2 = "distance_betweenness", hist=FALSE, point =T,
          steps = 30,
          esize = 2,
          ercolor = "black")+
  # Change the background
  # theme_bw() +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        panel.background = element_blank(), axis.line = element_line(colour = "black")) +
  # Add a horizontal line at y = 0
  geom_hline(yintercept = 0, linetype = "dashed") +
  # Add labels for X and Y axes
  xlab(expression(italic(D[i]))) +
  ylab(expression(paste('Coefficient of ', italic(E[i]), ' on ', italic(G[i]),' by levels of ', italic(D[i]))))+
  theme(axis.title=element_text(size=60),text = element_text(size=60))+
  theme(plot.title = element_text(face="bold")) +
  scale_x_continuous(breaks=c(0,2,4,6,8,10,12,14,16,18,20))
dev.off()

png("Main_interplot_madrid1.png", width=1200, height=1200)
interplot(m = madrid1i, var1 = "ellipticity", var2 = "distance_betweenness", hist=FALSE, point =T,
          steps = 30,
          esize = 2,
          ercolor = "black")+
  # Change the background
  # theme_bw() +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        panel.background = element_blank(), axis.line = element_line(colour = "black")) +
  # Add a horizontal line at y = 0
  geom_hline(yintercept = 0, linetype = "dashed") +
  # Add labels for X and Y axes
  xlab(expression(italic(D[i]))) +
  ylab(expression(paste('Coefficient of ', italic(E[i]), ' on ', italic(G[i]),' by levels of ', italic(D[i]))))+
  theme(axis.title=element_text(size=60),text = element_text(size=60))+
  theme(plot.title = element_text(face="bold")) +
  scale_x_continuous(breaks=c(0,2,4,6,8,10,12,14,16))
dev.off()


png("Main_interplot_bp1a.png", width=1200, height=1200)
interplot(m = bp1ai, var1 = "ellipticity", var2 = "distance_betweenness", hist=FALSE, point =T,
          steps = 30,
          esize = 2,
          ercolor = "black")+
  # Change the background
  # theme_bw() +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        panel.background = element_blank(), axis.line = element_line(colour = "black")) +
  # Add a horizontal line at y = 0
  geom_hline(yintercept = 0, linetype = "dashed") +
  # Add labels for X and Y axes
  xlab(expression(italic(D[i]))) +
  ylab(expression(paste('Coefficient of ', italic(E[i]), ' on ', italic(A[i]),' by levels of ', italic(D[i]))))+
  theme(axis.title=element_text(size=60),text = element_text(size=60))+
  theme(plot.title = element_text(face="bold")) +
  scale_x_continuous(breaks=c(0,2,4,6,8,10,12,14,16,18,20))
dev.off()


png("Main_interplot_helsinki1a.png", width=1200, height=1200)
interplot(m = helsinki1ai, var1 = "ellipticity", var2 = "distance_betweenness", hist=FALSE, point =T,
          steps = 30,
          esize = 2,
          ercolor = "black")+
  # Change the background
  # theme_bw() +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        panel.background = element_blank(), axis.line = element_line(colour = "black")) +
  # Add a horizontal line at y = 0
  geom_hline(yintercept = 0, linetype = "dashed") +
  # Add labels for X and Y axes
  xlab(expression(italic(D[i]))) +
  ylab(expression(paste('Coefficient of ', italic(E[i]), ' on ', italic(A[i]),' by levels of ', italic(D[i]))))+
  theme(axis.title=element_text(size=60),text = element_text(size=60))+
  theme(plot.title = element_text(face="bold")) +
  scale_x_continuous(breaks=c(0,2,4,6,8,10,12,14,16,18,20))
dev.off()

png("Main_interplot_madrid1a.png", width=1200, height=1200)
interplot(m = madrid1ai, var1 = "ellipticity", var2 = "distance_betweenness", hist=FALSE, point =T,
          steps = 30,
          esize = 2,
          ercolor = "black")+
  # Change the background
  # theme_bw() +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        panel.background = element_blank(), axis.line = element_line(colour = "black")) +
  # Add a horizontal line at y = 0
  geom_hline(yintercept = 0, linetype = "dashed") +
  # Add labels for X and Y axes
  xlab(expression(italic(D[i]))) +
  ylab(expression(paste('Coefficient of ', italic(E[i]), ' on ', italic(A[i]),' by levels of ', italic(D[i]))))+
  theme(axis.title=element_text(size=60),text = element_text(size=60))+
  theme(plot.title = element_text(face="bold")) +
  scale_x_continuous(breaks=c(0,2,4,6,8,10,12,14,16))
dev.off()


# 4.6 Consider socio-economic status of walking area - interactions

bp1_l=lm(gini_multimodal-gini_walk15 ~
           #area+
           gini_walk15+
           area_difference*ellipticity+
           distance_betweenness*ellipticity,
         data=bp[bp$arpu_low_ratio_walk15>
                   median(bp$arpu_low_ratio_walk15),])

bp1_h=lm(gini_multimodal-gini_walk15 ~
           #area+
           gini_walk15+
           area_difference*ellipticity+
           distance_betweenness*ellipticity,
         data=bp[bp$arpu_low_ratio_walk15<
                   median(bp$arpu_low_ratio_walk15),])

bp2_l=lm(gini_house_multimodal-gini_house_walk15 ~
           #area+
           gini_walk15+
           area_difference*ellipticity+
           distance_betweenness*ellipticity,
         data=bp[bp$mean_price<
                   median(bp$mean_price, na.rm = T),])

bp2_h=lm(gini_house_multimodal-gini_house_walk15 ~
           #area+
           gini_walk15+
           area_difference*ellipticity+
           distance_betweenness*ellipticity,
         data=bp[bp$mean_price>
                   median(bp$mean_price, na.rm = T),])

helsinki1_l=lm(weighted_gini_multi-weighted_gini_walk ~
                 #area+
                 weighted_gini_walk+
                 area_difference*ellipticity+
                 distance_betweenness*ellipticity,
               data=helsinki[helsinki$weighted_med_inc_walk<
                               median(helsinki$weighted_med_inc_walk),])

helsinki1_h=lm(weighted_gini_multi-weighted_gini_walk ~
                 #area+
                 weighted_gini_walk+
                 area_difference*ellipticity+
                 distance_betweenness*ellipticity,
               data=helsinki[helsinki$weighted_med_inc_walk>
                               median(helsinki$weighted_med_inc_walk),])

madrid1_l=lm(weighted_gini_multi-weighted_gini_walk ~
               #area+
               weighted_gini_walk+
               area_difference*ellipticity+
               distance_betweenness*ellipticity,
             data=madrid[madrid$weighted_net_income_hh_walk<
                           median(madrid$weighted_net_income_hh_walk),])

madrid1_h=lm(weighted_gini_multi-weighted_gini_walk ~
               #area+
               weighted_gini_walk+
               area_difference*ellipticity+
               distance_betweenness*ellipticity,
             data=madrid[madrid$weighted_net_income_hh_walk>
                           median(madrid$weighted_net_income_hh_walk),])

bp1a_l=lm(multimod_sum-walk_sum ~
            walk_sum+
            #area+
            area_difference*ellipticity+
            distance_betweenness*ellipticity,
          data=bp[bp$mean_price<
                    median(bp$mean_price, na.rm = T),])

bp1a_h=lm(multimod_sum-walk_sum ~
            walk_sum+
            #area+
            area_difference*ellipticity+
            distance_betweenness*ellipticity,
          data=bp[bp$mean_price>
                    median(bp$mean_price, na.rm = T),])

helsinki1a_l=lm(multimod_sum-walk_sum ~
                  walk_sum+
                  #area+
                  area_difference*ellipticity+
                  distance_betweenness*ellipticity,
                data=helsinki[helsinki$weighted_med_inc_walk<
                                median(helsinki$weighted_med_inc_walk),])

helsinki1a_h=lm(multimod_sum-walk_sum ~
                  walk_sum+
                  #area+
                  area_difference*ellipticity+
                  distance_betweenness*ellipticity,
                data=helsinki[helsinki$weighted_med_inc_walk>
                                median(helsinki$weighted_med_inc_walk),])

madrid1a_l=lm(multimod_sum-walk_sum ~
                walk_sum+
                #area+
                area_difference*ellipticity+
                distance_betweenness*ellipticity,
              data=madrid[madrid$weighted_net_income_hh_walk<
                            median(madrid$weighted_net_income_hh_walk),])

madrid1a_h=lm(multimod_sum-walk_sum ~
                walk_sum+
                #area+
                area_difference*ellipticity+
                distance_betweenness*ellipticity,
              data=madrid[madrid$weighted_net_income_hh_walk>
                            median(madrid$weighted_net_income_hh_walk),])

h1al = helsinki1a_l
m1al = madrid1a_l
b1al = bp1a_l
stargazer(h1al, m1al, b1al, helsinki1_l, madrid1_l, bp2_l, bp1_l,
          type="latex",
          style="aer",
          column.labels = c("Helsinki - Access",
                            "Madrid - Access",
                            "BP - Access",
                            "Helsinki - Gini",
                            "Madrid - Gini",
                            "BP residential - Gini",
                            "BP experienced - Gini"),
          dep.var.labels.include = F,
          out="SI_Reg_6_low.tex")


h1ah = helsinki1a_h
m1ah = madrid1a_h
b1ah = bp1a_h
h1h = helsinki1_h
m1h = madrid1_h
stargazer(h1ah, m1ah, b1ah, h1h, m1h, bp2_h, bp1_h,
          type="latex",
          style="aer",
          column.labels = c("Helsinki - Access",
                            "Madrid - Access",
                            "BP - Access",
                            "Helsinki - Gini",
                            "Madrid - Gini",
                            "BP residential - Gini",
                            "BP experienced - Gini"),
          dep.var.labels.include = F,
          out="SI_Reg_7_high.tex")


# 4.7 Correlation plots

# Load required package
library(corrplot)

# Define a helper function to create and save the correlation plot
plot_city_corr <- function(data, vars, filename) {
  df <- data[, vars]
  df <- na.omit(df)
  corr_mat <- cor(df, use = "complete.obs")

  png(filename, width = 800, height = 600)
  corrplot::corrplot(corr_mat, method = "color", type = "upper",
                     tl.col = "black", tl.srt = 45)
  dev.off()
}

# Variables for each city
vars_bp <- c("access_diff","gini_diff", "gini_diff_house", "walk_sum", "gini_walk15",
             "area_difference", "ellipticity", "distance_betweenness")
vars_he<- c("access_diff","gini_diff", "walk_sum","weighted_gini_walk",
            "area_difference", "ellipticity", "distance_betweenness")
vars_ma <- c("access_diff","gini_diff", "walk_sum","weighted_gini_walk",
             "area_difference", "ellipticity", "distance_betweenness")

# Create plots
plot_city_corr(bp, vars_bp, "SI_bp_corr.png")
plot_city_corr(helsinki, vars_he, "SI_helsinki_corr.png")
plot_city_corr(madrid, vars_ma, "SI_madrid_corr.png")


# 4.8 Variable Statistics

# Subset and drop missing data
bp_sub <- na.omit(bp[, vars_bp])
helsinki_sub <- na.omit(helsinki[, vars_he])
madrid_sub <- na.omit(madrid[, vars_ma])

# Write LaTeX summary tables
stargazer(bp_sub, type = "latex", out = "SI_summary_bp.tex",
          title = "Summary Statistics for Budapest",
          summary.stat = c("min", "p25", "median", "mean", "p75", "max", "sd"))

stargazer(helsinki_sub, type = "latex", out = "SI_summary_helsinki.tex",
          title = "Summary Statistics for Helsinki",
          summary.stat = c("min", "p25", "median", "mean", "p75", "max", "sd"))

stargazer(madrid_sub, type = "latex", out = "SI_summary_madrid.tex",
          title = "Summary Statistics for Madrid",
          summary.stat = c("min", "p25", "median", "mean", "p75", "max", "sd"))
