library(tidyverse)
library(car)
library(rstatix)
library(ggpubr)

data <- read_csv("data.csv") # use `setwd()` to change working directory.

# Removing training tasks
data <-  data %>% filter(task_code != 'v') %>% filter(task_code != 'w') %>% filter(task_code != 'x') %>% filter(task_code != 'y') %>% filter(task_code != 'z')

# Removing incomplete attempts
data <- data %>% filter(status != "incomplete")

# Each task can an outcome of 'success', 'skip', or 'timeout'. 
# We encode a new column 'success' with 1 if the participant finished the task
# or 0 if they skipped or timed out.
data <- mutate(data, success = ifelse(status == "success", 1, 0))

# Extract new dataframe with only dependent and independent variables.
anova_data = data %>% select(user_id, task_code, task_order, treatment, time_elapsed, success)

# Snapshot of the data used for linear models.
head(anova_data)

# Compute linear model for `time_elapsed` dependent variable. Blocking treatment with task_code and task_order.
model_time <- lm(time_elapsed ~ user_id + task_code + task_order + treatment, data = anova_data)

# Compute linear model for `success` dependent variable. Blocking treatment with task_code and task_order.
model_success = lm(success ~ user_id + task_code + task_order + treatment, data = anova_data)

# Anova analysis
Anova(model_time) # Anova takes cares of data set imbalances
Anova(model_success) 

# Normality assumption
ggqqplot(residuals(model_time))
ggqqplot(residuals(model_success))

shapiro_test(residuals(model_time)) # Normal. p-value not significant (p = 0.533)
shapiro_test(residuals(model_success)) # Normal. p-value not significant (p = 0.625)

# Normality assumption by groups
anova_data %>% group_by(treatment) %>% shapiro_test(time_elapsed) # Not normal! p < 0.05
anova_data %>% group_by(treatment) %>% shapiro_test(success) # Not normal! p < 0.05
ggqqplot(anova_data, "time_elapsed", facet.by = "treatment")
