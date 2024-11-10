# recipe_generator/urls.py
from django.urls import path
from . import views

app_name = 'recipe_generator'

urlpatterns = [
    path('', views.index, name='index'),
    path('generate/', views.generate_recipe, name='generate_recipe'),
    path('send-recipes/', views.send_recipes, name='send_recipes'),
    path('receive-recipes/', views.receive_recipes, name='receive_recipes'),
    path('generate_recipes/', views.fetch_and_generate_recipes,
         name='generate_recipes'),
]
