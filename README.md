# Projet-Cloud

Ce projet déploie une infrastructure cloud complète sur Azure avec Terraform, incluant une VM Ubuntu et un stockage Blob. Le backend Flask est connecté au stockage pour un CRUD de fichiers.

## Architecture

- **VM Ubuntu** : Machine virtuelle avec IP publique, accès SSH sécurisé.
- **Stockage Azure Blob** : Pour stocker des fichiers statiques, avec permissions privées.
- **Backend Flask** : Application Python avec CRUD pour les fichiers (upload, download, list, delete) via Azure Blob Storage.

## Prérequis

- Compte Azure avec abonnement actif.
- Terraform installé (version >= 1.0).
- Clé SSH publique pour accéder à la VM.
- Repo Git (GitHub, etc.) pour le code backend.

## Configuration

1. Créez un repo Git public et poussez le dossier `backend/` :
   ```
   git init
   git add backend/
   git commit -m "Initial commit"
   git remote add origin https://github.com/votre-user/votre-repo.git
   git push -u origin main
   ```

2. Copiez `terraform.tfvars.example` vers `terraform.tfvars` et remplissez :
   - `ssh_public_key` : Votre clé publique SSH.

3. Modifiez `main.tf` : Dans le `custom_data`, remplacez le TODO par :
   ```
   git clone https://github.com/votre-user/votre-repo.git /app
   cd /app
   systemctl enable flask-app
   systemctl start flask-app
   ```

4. Initialisez Terraform :
   ```
   terraform init
   ```

5. Planifiez :
   ```
   terraform plan
   ```

6. Appliquez :
   ```
   terraform apply
   ```

## Déploiement du Backend

Après `terraform apply`, la VM est créée avec Python installé et un service systemd configuré. Le backend se lance automatiquement si le repo est cloné.

Récupérez l'IP publique : `terraform output ip_publique_vm`

Testez le CRUD :
- Health : `curl http://<IP>:5000/health`
- List files : `curl http://<IP>:5000/files`
- Upload : `curl -F "file=@monfichier.txt" http://<IP>:5000/upload`
- Download : `curl http://<IP>:5000/download/monfichier.txt`
- Delete : `curl -X POST http://<IP>:5000/delete/monfichier.txt`

## Variables et Outputs

- Variables dynamiques dans `variables.tf`.
- Valeurs sensibles dans `terraform.tfvars`.
- Outputs : IPs et URLs dans `outputs.tf`.

## Nettoyage

```
terraform destroy
```

## Étape 5 : Tester et Détruire l’Infrastructure

### Tests à réaliser

1. **Accès à l'application** :
   - Récupérez l'IP publique : `terraform output ip_publique_vm`
   - Testez l'accès : `curl http://<IP>:5000/health`
   - Devrait retourner `{"status": "ok"}`

2. **Vérification du stockage cloud** :
   - Connectez-vous au portail Azure ou utilisez Azure CLI :
     ```
     az storage blob list --account-name $(terraform output nom_stockage) --container-name fichiers --auth-mode key
     ```
   - Vérifiez que les fichiers uploadés via l'API sont présents.

3. **Opérations CRUD** :
   - **Create/Upload** : `curl -F "file=@test.txt" http://<IP>:5000/upload`
   - **Read/List** : `curl http://<IP>:5000/files`
   - **Read/Download** : `curl http://<IP>:5000/download/test.txt`
   - **Delete** : `curl -X POST http://<IP>:5000/delete/test.txt`
   - Base de données : Non implémentée (optionnelle), mais le CRUD est pour les fichiers dans le stockage cloud.

### Suppression de l’infrastructure

Une fois les tests terminés, supprimez tout :
```
terraform destroy
```
Confirmez avec `yes` pour détruire les ressources Azure.

## Notes

- La DB est optionnelle ; le backend actuel n'en utilise pas.
- Pour automatiser le déploiement du code, ajoutez un repo Git dans le script `custom_data`.