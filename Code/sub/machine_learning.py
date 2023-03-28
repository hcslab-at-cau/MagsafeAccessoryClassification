from sklearn.neighbors import KNeighborsClassifier
import matplotlib.pyplot as plt
from sklearn.ensemble import RandomForestClassifier
from sklearn.svm import SVC
import pandas as pd

def get_knn(n = 20):
  knn = KNeighborsClassifier(n)

  return knn

def knn_n_affect(knn, X, y, test_data, test_labels):
  k_list = range(1,100)
  accuracies = []

  for k in k_list:
    classifier = KNeighborsClassifier(n_neighbors = k)
    classifier.fit(X, y)
    accuracies.append(classifier.score(test_data, test_labels))

  plt.plot(k_list, accuracies)
  plt.xlabel("k")
  plt.ylabel("Validation Accuracy")
  plt.title("KNN Classifier Accuracy")
  plt.show()

def get_rf(n = 100):
  rf = RandomForestClassifier(n_estimators=n, random_state=42)

  return rf

def rf_n_affect(rf, X, y, test_data, test_labels):
  k_list = range(1,100)
  accuracies = []

  for k in k_list:
    classifier = RandomForestClassifier(n_estimators=k, random_state=42)
    classifier.fit(X, y)
    accuracies.append(classifier.score(test_data, test_labels))

  plt.plot(k_list, accuracies)
  plt.xlabel("k")
  plt.ylabel("Validation Accuracy")
  plt.title("Random forest Classifier Accuracy")
  plt.show()

def get_svm(kernel_type = 'linear'):
  svm = SVC(kernel = kernel_type)

  return svm

def train_models(models, df):
    X = df.drop('Label', axis = 1)
    y = df['Label']
    trained_model = []
    
    for key, model in models.items():
        model.fit(X, y)
        
    return models

def test_models(models, test_data, test_labels):
    for model_name, model in models.items():
        print('{} Accuracy {:.3f}'.format(model_name, model.score(test_data, test_labels)))

def ml_score(models, df_lst):
  scores = {x : [] for x in ['knn', 'svm', 'rf']}

  for i, df in enumerate(df_lst):
    print("{}th accuary".format(i))
    
    test_data = df.drop('Label', axis = 1)
    test_label = df['Label']
    for key, model in models.items():
      scores[key].append(model.score(test_data, test_label))
      print('{} : {:.3f}'.format(key, model.score(test_data, test_label)))
    print()
  return scores

def plot_score(x, scores, title = "score"):
  for model, score in scores.items():
    plt.plot(x, score, '-o', label=model)
  plt.title(title)
  plt.legend(loc='lower left')

  plt.show()

def total_plot(models, df_lst, x, labels):
  for label in labels:
    print("{} plot".format(label))

    scores = ml_score(models, df_lst[label])
    plot_score(x, scores, title = label)

      
def find_model_error(model, test_data, test_label):
    mag = ['magX', 'magY', 'magZ']
            
    for i in range(len(test_label)):
        tmp = {m : [] for m in mag}
        
        for m in mag:
            tmp[m].append(test_data[m][i])
        tmp = pd.DataFrame(tmp)
    
        p = model.predict(tmp)[0]
        if p != test_label[i]:
            print('test label is {}, but predicted {} with values ({}, {}, {})'.format(
            test_label[i], p, tmp[mag[0]], tmp[mag[1]], tmp[mag[2]]))

