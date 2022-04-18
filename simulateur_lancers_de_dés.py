import random

d = ['4', '6', '8', '10', '12', '20', '100']
megatotal = []

for index, type_de_d in enumerate(d):
    nombre_de_faces = int(d[index])
    nombre_de_lancers = int(input('Combien de d' + type_de_d + ' voulez-vous lancer ? ') or 0)
    if nombre_de_lancers > 0:
        total = []
        while nombre_de_lancers > 0:
            lancer = int(random.randint(1, nombre_de_faces))
            total.append(lancer)
            megatotal.append(lancer)
            nombre_de_lancers -= 1
        print(*total, sep='+')
        print('=', sum(total))
    print()
print('TOTAL :', sum(megatotal))
