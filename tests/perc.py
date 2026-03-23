
def fixed_list(list,n):
    x2=[]
    finlist=[]
    for x in list:
        x2.append(x)
        if len(x2)==n:
            finlist.append(x2)
            x2=[]
        if len(x2)==n:
            finlist.append(x2)
            x2=[]
        else:
            if len(x2)>0:
                print("Warning: list size is not multiple of n")
    return finlist

def weighted_sum(x,weights):
    sum=0
    for x1,x2 in zip(x,weights):
        sum+=x1*x2
    return sum

def activation(sum):
    if sum>=0:
        return 1
    else:
        return 0
    
def learn_weights(x,desired,weights,alpha):
    sum=weighted_sum(x,weights)
    out=activation(sum)
    for i in range(len(weights)):
        weights[i]=weights[i]+alpha*(desired-out)*x[i]
    return weights

def read_two_lists(filename):
    with open(filename, "r") as f:
        lines = f.read().splitlines()  

    list1 = list(map(float, lines[0].split()))  
    list2 = list(map(float, lines[1].split()))  

    return list1, list2

def get_weights(size):
    w=[]
    for i in range(size):
        w.append(0.0)
    return w
    
def verify(x,desired,weights):
    for el in x:
        sum=weighted_sum(el,weights)
        out=activation(sum)
        if out!=desired:
            return False
    return True


list1, list2 = read_two_lists("fisierInputs.txt")
x=fixed_list(list1,2)
alpha=0.1
w=get_weights(len(x[0]))
for i in range(len(x)):
    w=learn_weights(x[i],list2[i],w,alpha)

