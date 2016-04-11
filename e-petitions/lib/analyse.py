# coding=utf-8

from collections import Counter
from textblob import TextBlob, Word
import re
import pandas as pd
from numpy import log

def loglikely(n1, t1, n2, t2, add1=False):
    """Calculates Dunning log likelihood of an observation of
    frequency n1 in a corpus of size t1, compared to a frequency n2
    in a corpus of size t2. If result is positive, it is more
    likely to occur in corpus 1, otherwise in corpus 2."""
    from numpy import log
    if add1:
        n1 += 1
        n2 += 1
    try:
        e1 = t1*1.0*(n1+n2)/(t1+t2) # expected values
        e2 = t2*1.0*(n1+n2)/(t1+t2)
        LL = 2 * ((n1 * log(n1/e1)) + n2 * (log(n2/e2)))
        if n2*1.0/t2 > n1*1.0/t1:
            LL = -LL
        return LL
    except:
        return None

# load csv and name columns
df = pd.read_csv('wtp_data_petitions.csv', index_col=None, names=['serial',
                 'id', 'type', 'title',  'body', 'signature_threshold',
                 'signature_count', 'signatures_needed', 'url', 'deadline',
                 'status', 'created'])

# 'created' column is in epoch seconds; change to timestamp
df['created'] = pd.to_datetime(df['created'],unit='s')

# view first record
df.iloc[0]


# limit to petitions after their deadlines.
# 'Reviewed' means a successful petition, 'Closed' unsuccessful
df = df[df.status.isin(['Reviewed', 'Closed'])]

# Create four counters, of title and body
# Note that only body was used for this analysis
# Title did not result in substantially different results
# except for having fewer words

counts = {'Reviewed': {'title': Counter(), 'body': Counter()},
          'Closed': {'title': Counter(), 'body': Counter()}}

for idx, row in df.iterrows():
    status = row.status
    for sample in ['title', 'body']:
        text = row[sample].lower()
        # the text is full of periods without following spaces, e.g.
        # "...this petition.Therefore, ..." Replace them with spaces.
        text = re.sub('([a-z])\.([a-z])', r'\1. \2', text)
        words = TextBlob(text.decode('utf-8')).words
        # Set used in order not to multiple-count words that appear more
        # than once in a petition
        lemmas = set([Word(x).lemmatize() for x in words])
        counts[status][sample].update(list(lemmas))


# total size of each corpus (Reviewed and Closed)

t1, t2 = {}, {}
for sample in ['title', 'body']:
    t1[sample] = sum(counts['Reviewed'][sample].values())
    t2[sample] = sum(counts['Closed'][sample].values())

# Calculate frequency per thousand petitions for each word

fpt = {'Reviewed': {'title': {}, 'body': {}},
       'Closed': {'title': {}, 'body': {}}}

for status in ['Reviewed', 'Closed']:
    length = len(df[df.status == status])
    for sample in ['title', 'body']:
        for lemma, count in counts[status][sample].items():
            fpt[status][sample][lemma] = count * 1000.0 / length

# calculate log-likelihoods

word2LL = {'title': {}, 'body': {}}
for sample in ['title', 'body']:
    for lemma, n1 in counts['Reviewed'][sample].items():
        if lemma in counts['Closed'][sample].keys():
            word2LL[sample][lemma] = loglikely(n1, t1[sample],
                                               counts['Closed'][sample][lemma],
                                               t2[sample], add1=True)

dfb = pd.DataFrame.from_dict(word2LL['body'], orient='index')
dfb.columns = ['LL_body']
dfb.sort_values('LL_body', ascending=False, inplace=True)
dfb['reviewed_fpt'] = [fpt['Reviewed']['body'][x] if x in fpt['Reviewed']['body'].keys() else 0 for x in dfb.index]
dfb['closed_fpt'] = [fpt['Closed']['body'][x] if x in fpt['Closed']['body'].keys() else 0 for x in dfb.index]
print(dfb.head())
print(dfb.tail())


dfb.to_csv('whitehouse_petitions_keyness.csv',encoding = "utf-8")

df['body_lower'] = df.body.apply(lambda x: x.lower())
df['title_lower'] = df.title.apply(lambda x: x.lower())
text = []
deactivated = False
for idx, row in dfb.iterrows():
    if row.name == 'condition':
        deactivated = False
    if not deactivated:
        df_ = df[df.body_lower.str.contains(row.name)]
        assert len(df_) >= 5
        df_ = df_.sample(n=5)
        text.append(row.name)
        for idx2, row2 in df_.iterrows():
            item = '- '+row2.title
            text.append(item)
        text.append('')
    if row.name == 'regulation':
        deactivated = True

# encoding issues on this line
# UnicodeDecodeError: 'ascii' codec can't decode byte 0xe2 in position 59: ordinal not in range(128)
with open('LL_samples.txt', 'w+') as f:
    f.write('\n'.join(text))
