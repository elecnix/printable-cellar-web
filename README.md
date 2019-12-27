# Générateur d'étiquettes pour la Société des alcools du Québec

Ceci est une application web en Rails qui sert à générer des étiquettes du Célier imprimable.

Site démo: http://printable-cellar.herokuapp.com

    bundle install
    mkdir certificates
    openssl req -x509 -newkey rsa:4096 -keyout certificates/key.pem -out certificates/cert.pem -days 365
    bundle exec script/rails server
