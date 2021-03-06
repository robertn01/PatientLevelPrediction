% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/RunPlp.R
\name{runPlp}
\alias{runPlp}
\title{runPlp - Train and evaluate the model}
\usage{
runPlp(population, plpData, minCovariateFraction = 0.001, normalizeData = T,
  modelSettings, testSplit = "time", testFraction = 0.25,
  trainFraction = NULL, splitSeed = NULL, nfold = 3, indexes = NULL,
  saveDirectory = NULL, savePlpData = T, savePlpResult = T,
  savePlpPlots = T, saveEvaluation = T, verbosity = "INFO",
  timeStamp = FALSE, analysisId = NULL, save = NULL)
}
\arguments{
\item{population}{The population created using createStudyPopulation() who will be used to develop the model}

\item{plpData}{An object of type \code{plpData} - the patient level prediction
data extracted from the CDM.}

\item{minCovariateFraction}{The minimum fraction of target population who must have a covariate for it to be included in the model training}

\item{normalizeData}{Whether to normalise the covariates before training (Default: TRUE)}

\item{modelSettings}{An object of class \code{modelSettings} created using one of the function:
\itemize{
\item{setLassoLogisticRegression()}{ A lasso logistic regression model}
\item{setGradientBoostingMachine()}{ A gradient boosting machine}
\item{setAdaBoost()}{ An ada boost model}
\item{setRandomForest()}{ A random forest model}
\item{setDecisionTree()}{ A decision tree model}
\item{setCovNN())}{ A convolutional neural network model}
\item{setCIReNN()}{ A recurrent neural network model}
\item{setMLP()}{ A neural network model}
\item{setDeepNN()}{ A deep neural network model}
\item{setKNN()}{ A KNN model}

}}

\item{testSplit}{Either 'person' or 'time' specifying the type of evaluation used.
'time' find the date where testFraction of patients had an index after the date and assigns patients with an index prior to this date into the training set and post the date into the test set
'person' splits the data into test (1-testFraction of the data) and
train (validationFraction of the data) sets.  The split is stratified by the class label.}

\item{testFraction}{The fraction of the data to be used as the test set in the patient
split evaluation.}

\item{trainFraction}{A real number between 0 and 1 indicating the train set fraction of the data.
If not set trainFraction is equal to 1 - test}

\item{splitSeed}{The seed used to split the test/train set when using a person type testSplit}

\item{nfold}{The number of folds used in the cross validation (default 3)}

\item{indexes}{A dataframe containing a rowId and index column where the index value of -1 means in the test set, and positive integer represents the cross validation fold (default is NULL)}

\item{saveDirectory}{The path to the directory where the results will be saved (if NULL uses working directory)}

\item{savePlpData}{Binary indicating whether to save the plpData object (default is T)}

\item{savePlpResult}{Binary indicating whether to save the object returned by runPlp (default is T)}

\item{savePlpPlots}{Binary indicating whether to save the performance plots as pdf files (default is T)}

\item{saveEvaluation}{Binary indicating whether to save the oerformance as csv files (default is T)}

\item{verbosity}{Sets the level of the verbosity. If the log level is at or higher in priority than the logger threshold, a message will print. The levels are:
\itemize{
\item{DEBUG}{Highest verbosity showing all debug statements}
\item{TRACE}{Showing information about start and end of steps}
\item{INFO}{Show informative information (Default)}
\item{WARN}{Show warning messages}
\item{ERROR}{Show error messages}
\item{FATAL}{Be silent except for fatal errors}
}}

\item{timeStamp}{If TRUE a timestamp will be added to each logging statement. Automatically switched on for TRACE level.}

\item{analysisId}{Identifier for the analysis. It is used to create, e.g., the result folder. Default is a timestamp.}

\item{save}{Old input - please now use saveDirectory}
}
\value{
An object containing the model or location where the model is save, the data selection settings, the preprocessing
and training settings as well as various performance measures obtained by the model.

\item{predict}{A function that can be applied to new data to apply the trained model and make predictions}
\item{model}{A list of class \code{plpModel} containing the model, training metrics and model metadata}
\item{prediction}{A dataframe containing the prediction for each person in the test set }
\item{evalType}{The type of evaluation that was performed ('person' or 'time')}
\item{performanceTest}{A list detailing the size of the test sets}
\item{performanceTrain}{A list detailing the size of the train sets}
\item{time}{The complete time taken to do the model framework}
}
\description{
This provides a general framework for training patient level prediction models.  The user can select 
various default feature selection methods or incorporate their own,  The user can also select from
a range of default classifiers or incorporate their own.  There are three types of evaluations for the model
patient (randomly splits people into train/validation sets) or year (randomly splits data into train/validation sets
based on index year - older in training, newer in validation) or both (same as year spliting but checks there are
no overlaps in patients within training set and validaiton set - any overlaps are removed from validation set)
}
\details{
Users can define a risk period of interest for the prediction of the outcome relative to index or use
the cohprt dates.  The user can then specify whether they wish to exclude patients who are not observed
during the whole risk period, cohort period or experienced the outcome prior to the risk period.
}
\examples{
\dontrun{
#******** EXAMPLE 1 ********* 
#load plpData:
plpData <- loadPlpData(file.path('C:','User','home','data'))

#create study population to develop model on
#require minimum of 365 days observation prior to at risk start
#no prior outcome and person must be observed for 365 after index (minTimeAtRisk)
#with risk window from 0 to 365 days after index
population <- createStudyPopulation(plpData,outcomeId=2042,
                                    firstExposureOnly = FALSE,
                                    washoutPeriod = 365,
                                    removeSubjectsWithPriorOutcome = TRUE,
                                    priorOutcomeLookback = 99999,
                                    requireTimeAtRisk = TRUE,
                                    minTimeAtRisk=365,
                                    riskWindowStart = 0,
                                    addExposureDaysToStart = FALSE,
                                    riskWindowEnd = 365,
                                    addExposureDaysToEnd = FALSE)

#lasso logistic regression predicting outcome 200 in cohorts 10 
#using no feature selection with a time split evaluation with 30\% in test set
#70\% in train set where the model hyper-parameters are selected using 3-fold cross validation:
#and results are saved to file.path('C:','User','home')
model.lr <- lassoLogisticRegression.set()
mod.lr <- runPlp(population=population,
                        plpData= plpData, minCovariateFraction = 0.001,
                        modelSettings = model.lr ,
                        testSplit = 'time', testFraction=0.3, 
                        nfold=3, indexes=NULL,
                        saveDirectory =file.path('C:','User','myPredictionName'),
                        verbosity='INFO')
 
#******** EXAMPLE 2 *********                                               
# Gradient boosting machine with a grid search to select hyper parameters  
# using the test/train/folds created for the lasso logistic regression above                       
model.gbm <- gradientBoostingMachine.set(rsampRate=c(0.5,0.9,1),csampRate=1, 
                           ntrees=c(10,100), bal=c(F,T),
                           max_depth=c(4,5), learn_rate=c(0.1,0.01))
mod.gbm <- runPlp(population=population,
                        plpData= plpData,
                        modelSettings = model.gbm,
                        testSplit = 'time', testFraction=0.3, 
                        nfold=3, indexes=mod.lr$indexes,
                        saveDirectory =file.path('C:','User','myPredictionName2'))
} 
}
