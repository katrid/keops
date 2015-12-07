from katrid.shortcuts import render


def login(request):
    return render(request, 'keops/auth/login.html')
