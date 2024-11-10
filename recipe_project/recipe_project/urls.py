# recipe_project/urls.py
from django.contrib import admin
from django.urls import path, include
from django.shortcuts import redirect


def redirect_to_recipe(request):
    return redirect('recipe_generator:index')


urlpatterns = [
    path('admin/', admin.site.urls),
    path('recipe/', include('recipe_generator.urls', namespace='recipe_generator')),
    path('', redirect_to_recipe, name='home'),
]
