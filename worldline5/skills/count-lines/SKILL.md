---
name: count-lines
description: 'Compte les fichiers et les lignes de code d''un projet, fichier par fichier, avec total. Ignore les fichiers binaires (images, polices, archives, exécutables). USE WHEN l''utilisateur demande combien de lignes de code, nombre de fichiers, taille du projet, statistiques du code, LOC, cloc, compter les lignes.'
argument-hint: 'Dossier à analyser (par défaut : racine du workspace)'
---

# Comptage des lignes de code

Produit un rapport : nombre de fichiers texte, lignes par fichier, total des lignes du projet.

## Procédure

1. Déterminer le dossier cible : l'argument fourni, sinon la racine du workspace.
2. Exécuter le script adapté à l'OS dans un terminal (les deux produisent la même sortie) :
   - **Windows** — [count-lines.ps1](./scripts/count-lines.ps1) :
     ```powershell
     & "<chemin-du-skill>/scripts/count-lines.ps1" -Path "<dossier-cible>"
     ```
   - **Linux / macOS** — [count-lines.sh](./scripts/count-lines.sh) :
     ```bash
     bash "<chemin-du-skill>/scripts/count-lines.sh" "<dossier-cible>"
     ```
   - Dans un dépôt git, la liste des fichiers vient de `git ls-files` (le `.gitignore` est respecté, fichiers non suivis inclus).
   - Sinon, parcours récursif avec dossiers exclus par défaut : `.git`, `node_modules`, `dist`, `build`, `bin`, `obj`, `.vscode`, `.venv`, etc. Surcharger si l'utilisateur le demande : `-ExcludeDirs a,b` (PowerShell) ou arguments supplémentaires `<dossier-cible> a b` (bash).
   - Un fichier est considéré binaire si son extension est connue (images, audio, vidéo, polices, archives, exécutables, PDF, Office) ou s'il contient un octet nul dans ses 8 premiers Ko.
3. Présenter le résultat dans le chat :
   - Un tableau Markdown `Fichier | Lignes`, trié par nombre de lignes décroissant, avec liens vers les fichiers. Toutes les lignes sont comptées (vides incluses).
   - Un résumé : mode utilisé (git ou parcours), nombre de fichiers texte analysés, nombre de fichiers binaires ignorés, **total des lignes**.
4. Ne jamais compter manuellement en lisant les fichiers : toujours s'appuyer sur la sortie du script.
