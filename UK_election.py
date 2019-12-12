# British election modeling
# Take covariates from 2017 results, YouGov MRP, and Leave vote; predict unannounced races with a
# simple model built from announced results
import pandas as pd
import sklearn
from sklearn.linear_model import LinearRegression

# working data file, plus mrp
live = pd.read_excel('data/mrp_and_live.xlsx')

# Data from https://data.gov.uk/dataset/b77fcedb-4792-4de4-935f-4f344ed4c2c6/general-election-results-2017
data = pd.read_excel('data/2017-UK-Electoral-Data.xls', sheet_name='Results', header=1)
data = data[['Constituency', 'Valid votes', 'Party Identifer']]
data.columns = ['Constituency', 'votes', 'party']

# delete other parties
mainParties = ['Conservative', 'Labour', 'Liberal Democrats']
data = data[data.party.isin(mainParties)]

# fix a few constituencies
data['Constituency'] = data['Constituency'].replace('Brecon and Radnorshire 5', 'Brecon and Radnorshire')

data = data.pivot_table(index='Constituency', columns = 'party', values = 'votes')

# and turnout
turnout = pd.read_excel('data/2017-UK-Electoral-Data.xls', sheet_name='Administrative data', header=2)
turnout = turnout[['Constituency', 'Valid vote turnout (all valid votes)']]
turnout.columns = ['Constituency', 'turnout']

data = pd.merge(data, turnout, on = 'Constituency', how = 'outer')

# and brexit vote
# Data from https://commonslibrary.parliament.uk/parliament-and-elections/elections-elections/brexit-votes-by-constituency/
brexit = pd.read_excel('data/eureferendum_constituency.xlsx', sheet_name='DATA', header = 5)
brexit = brexit[['ONS ID', 'Constituency', 'TO USE']]
brexit.columns = ['ONS ID', 'Constituency', 'leave']
brexit = brexit.dropna()

data = pd.merge(data, brexit, on = 'Constituency', how = 'outer')

# and live/mrp, dropping non-main parties
live = live.drop(['Brexit_MRP', 'Green_MRP', 'SNP_MRP', 'PC_MRP', 'Other_MRP'], 1)
data = pd.merge(data, live, on = 'Constituency', how = 'outer')
data = data.drop(['Constituency', 'ONS ID', 'code'], 1)

# Create and spilt training set
train_set = data.dropna(subset=['Con_Live'])
train_coeffs = train_set.drop([col for col in train_set if col.endswith('_Live')], axis=1)
train_outcomes = train_set[[col for col in train_set if col.endswith('_Live')]]

# train model with results so far
lr = LinearRegression().fit(train_coeffs, train_outcomes)

# Create prediction set
pred_set = data[data['Con_Live'].isnull()]
pred_set = pred_set.drop([col for col in train_set if col.endswith('_Live')], axis=1)

# drop all our NAs
pred_set = pred_set.dropna()

# run predict
pred_outcomes = pd.DataFrame(lr.predict(pred_set))
pred_outcomes.columns = train_outcomes.columns

# count predicted winners
pred_outcomes['C_win'] = (pred_outcomes['Con_Live'] > pred_outcomes['Lab_Live']) & (pred_outcomes['Con_Live'] > pred_outcomes['LD_Live'])
pred_outcomes['Lab_win'] = (pred_outcomes['Lab_Live'] > pred_outcomes['Con_Live']) & (pred_outcomes['Lab_Live'] > pred_outcomes['LD_Live'])
pred_outcomes['LD_win'] = (pred_outcomes['LD_Live'] > pred_outcomes['Con_Live']) & (pred_outcomes['LD_Live'] > pred_outcomes['Lab_Live'])

sum(pred_outcomes['C_win'])
sum(pred_outcomes['Lab_win'])
sum(pred_outcomes['LD_win'])
