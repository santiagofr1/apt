# apt.santiagofr1

Repo apt propio con los paquetes `.deb` de mis proyectos open source, firmados con GPG y publicados en GitHub Pages:
**https://santiagofr1.github.io/apt**

## Instalar

```sh
sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://santiagofr1.github.io/apt/key.asc | sudo gpg --dearmor -o /etc/apt/keyrings/santiagofr1.gpg
echo "deb [signed-by=/etc/apt/keyrings/santiagofr1.gpg] https://santiagofr1.github.io/apt stable main" | sudo tee /etc/apt/sources.list.d/santiagofr1.list
sudo apt update
sudo apt install rtop
```

| Paquete | Qué es |
|---|---|
| [rtop](https://github.com/santiagofr1/rtop) | Monitor del sistema para Linux (TUI y GUI) |

## Cómo funciona

```
app (ej. rtop) ── push ──▶ su workflow compila y publica el .deb en sus Releases
                                     │  (avisa con repository_dispatch, o lo levanta el cron horario)
                                     ▼
este repo ── build.sh ──▶ baja los .deb de los Releases de cada app de apps.txt
                          arma pool/ + Packages + Release, firma InRelease
                          ──▶ GitHub Pages
```

- No guarda binarios en git: en cada corrida se arma todo de cero a partir de los Releases. Cada app borra sus Releases viejos, así que acá quedan solo las últimas versiones.
- La firma usa la clave del secret `APT_GPG_PRIVATE_KEY`. La pública está en [`key.asc`](key.asc).
- Huella de la clave: `044E C70F DD4B 244C 570D  8EDC BB94 2FED C223 C785`

## Sumar una app nueva

1. En el repo de la app, que su workflow publique el `.deb` como asset de un Release (ver [el de rtop](https://github.com/santiagofr1/rtop/blob/master/.github/workflows/deb.yml)). La versión tiene que subir en cada build.
2. Agregar `usuario/repo` a [`apps.txt`](apps.txt) y sumarla a la tabla de arriba y a `index.html`.
3. Opcional, para que se publique al instante y no en la próxima hora: cargar en la app el secret `APT_DISPATCH_TOKEN`, un fine-grained token con permiso *Contents: read and write* sobre este repo.

## Probar local

```sh
./build.sh      # necesita gh, apt-utils y la clave privada en el llavero
```

Licencia MIT.
