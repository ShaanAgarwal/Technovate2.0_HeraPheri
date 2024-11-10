# recipe_generator/models.py
from django.db import models


class Recipe(models.Model):
    # Removed the incorrect 'str =' part
    title = models.CharField(max_length=200)
    ingredients = models.TextField()
    instructions = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.title
