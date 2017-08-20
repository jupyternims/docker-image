#!/usr/bin/sage

from sage.misc.misc import DOT_SAGE
from sagenb.notebook import notebook
directory = DOT_SAGE+'sage_notebook'
nb = notebook.load_notebook(directory)
nb.user_manager().add_user('admin', 'jovyan', '', force=True)
nb.save()
