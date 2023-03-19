import random
import json


def getRandomNumber(max, min):
    randomDouble = random.uniform(0, 1)
    result = int(min + (max-min)*(1 - randomDouble**0.5))
    return result
    

def main():
    max = 5000
    min = 0
    iterations = 100000000
    occurences = {}
    probabilities = {}
    for i in range(min, max + 1):
        occurences[i] = 0
        probabilities[i] = 0
    for i in range(iterations):
        num = getRandomNumber(max, min)
        occurences[num] += 1
        probabilities[num] = float(occurences[num])/iterations*100

    with open('probabilities.json', 'w') as outfile:
        json.dump(probabilities, outfile)


if __name__ == "__main__":
    main()