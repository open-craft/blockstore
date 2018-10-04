"""
Tagstore backend that uses the django ORM
"""
from django.db import models

MAX_CHAR_FIELD_LENGTH = 180


class Taxonomy(models.Model):
    """
    A taxonomy is a collection of tags, some of which may be organized into
    a hierarchy.
    """
    id = models.BigAutoField(primary_key=True)
    name = models.CharField(max_length=MAX_CHAR_FIELD_LENGTH)
    owner_id = models.BigIntegerField(null=False)

    class Meta:
        db_table = 'tagstore_taxonomy'


class Tag(models.Model):
    """
    A tag within a taxonomy
    """
    id = models.BigAutoField(primary_key=True)
    taxonomy = models.ForeignKey(Taxonomy, null=False)
    # The tag string, like "good problem".
    # The migration creates an uppercase index on this field for
    # case-insensitive searches
    tag = models.CharField(max_length=MAX_CHAR_FIELD_LENGTH)
    # Materialized path. Always ends with "/".
    # A simple tag like "good-problem" would have a path of "good-problem/"
    # A tag like "mammal" that is a child of "animal" would have a path of
    # "animal/mammal/". Tags are not allowed to contain the "/" character
    # so no escaping is necessary.
    path = models.CharField(max_length=MAX_CHAR_FIELD_LENGTH, db_index=True)

    class Meta:
        db_table = 'tagstore_tag'
        ordering = ('tag', )
        unique_together = (
            ('taxonomy', 'tag'),
            # Note that (taxonomy, path) is also unique but we don't bother
            # with an index for that.
        )

    @staticmethod
    def make_path(taxonomy_id: int, tag: str, parent_path: str = '') -> str:
        """
        Return the full 'materialized path' for use in the path field.

        make_path(15, 'easy') -> '15/easy/'
        make_path(200, 'lion', 'animal/mammal/') -> '200/animal/mammal/lion/'
        """
        prefix = str(taxonomy_id) + '/'
        if parent_path:
            assert parent_path.startswith(prefix)
            return parent_path + tag + '/'
        else:
            return prefix + tag + '/'


class Entity(models.Model):
    """
    An entity that can be tagged.
    """
    id = models.BigAutoField(primary_key=True)
    entity_type = models.CharField(max_length=MAX_CHAR_FIELD_LENGTH)
    external_id = models.CharField(max_length=255)

    tags = models.ManyToManyField(Tag)

    class Meta:
        unique_together = (
            ('entity_type', 'external_id'),
        )
        db_table = 'tagstore_entity'
