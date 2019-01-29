import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

nums = [10, 50, 100, 250, 500, 750, 1000]
algorithms = ["MENGELKAMP", "PRICE_TIME_BASED"]

ax = None
all = None
for algorithm in algorithms:
    for num in nums:
        name = str(num)
        df = pd.read_csv('rawData/'+algorithm+'/'+name+'_actions_20_percent_bids.csv', skiprows = 0)
        df['num actions'] = num
        df['algorithm'] = algorithm
        df['clearing'] = False
        if algorithm == "MENGELKAMP":
            df.iat[num, 5] = True
        if (all is None):
            all = df
        else:
            all = pd.concat([all, df])
nonClearings = all[(all['clearing'] == False)]
clearings = all[(all['clearing'] == True)]
plt.figure(1)
ax = plt.subplot(221)
for index, group in all.groupby(['algorithm']):
    group_agg = group.groupby(['num actions']).sum()
    group_agg.plot(y='gas used', label=index, ax=ax)
ax.set(xlabel='#Placed Bids & Asks', ylabel='Total Gas Usage', title="Total Gas Usage Per Algorithm and #Bids & Asks")

plt.subplot(222)
ax = sns.lineplot(x="num actions", y="gas used", data=clearings, hue="algorithm")
ax.set(xlabel='#Placed Bids & Asks', ylabel='Gas Usage for Clearing', title="Gas Usage For Clearing in Mengelkamp Algorithm")
plt.axhline(y=8000000, color='r', linestyle='-')

plt.subplot(212)
ax = sns.boxplot(x="num actions", y="gas used", hue="algorithm", data=nonClearings, palette="Set3")
ax.set(xlabel='#Placed Bids & Asks', ylabel='Gas Usage per Bid/Ask', title="Gas Usage For Placing Bids/Asks")

#print(all.tail(5))
    #df = df.rename(index=str, columns={"gas used": name})
    #ax = df.boxplot(column=[name], return_type="axes", ax=ax)

#ax = df.boxplot(column=['gas used'], return_type="axes")
#df2.boxplot(column=['gas used'], ax=ax)

plt.show()

#df2['test'] = df['gas used']

#df2.boxplot(column=['gas used', 'test'], return_type="axes")
#plt.show()
#print(df2.head(15))