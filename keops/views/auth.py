from katrid.shortcuts import render
from katrid.contrib.auth import authenticate


def login(request):
    if request.method == 'POST':
        post = request.POST
        email = post['email']
        pwd = post['password']
        u = authenticate(email=email, password=pwd)
        print(u)
    return render(request, 'apps/auth/login.html')
