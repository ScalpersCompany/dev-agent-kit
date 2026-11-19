# Conectar con scalpers-tech-doc

`ScalpersCompany/scalpers-tech-doc` es la base documental y la norma de empresa. El kit y
los perfiles son herramientas de desarrollo. Son repos separados y siguen siéndolo: cada
uno tiene su remoto, sus permisos y su dueño.

## Reparto de responsabilidades

```text
ScalpersCompany/scalpers-tech-doc   norma, procesos, decisiones, propuestas, wiki
ScalpersCompany/dev-agent-kit        puerta de calidad, hooks, guard, verify, evals
ScalpersCompany/dev-agent-profiles  perfiles Odoo 11 y PHP
repos de producto                  código de la base de desarrollo (GitLab); no hay un repo único
```

El código no se copia en la documentación y la documentación no se copia en el kit. Se
conectan por **contratos y enlaces**, no por fusión de repos.

## Contratos

1. **Norma canónica**: `scalpers-tech-doc/AGENTS.md`. En esta máquina está enlazada como
   `~/.agents/AGENTS.md`, y `SOUL.md`, `AGENTS.md` de OpenCode y `CLAUDE.md` apuntan a
   ella. Es la norma que leen todos los agentes.
2. **Contrato local del kit**: `dev-agent-kit/AGENTS.md` solo contiene las reglas del
   repositorio de herramientas. Si choca con la norma de empresa, gana la de empresa.
3. **Reglas del lenguaje**: el `AGENTS.fragment.md` del perfil (Odoo 11) añade lo que la
   norma general no sabe: ORM v11, `sudo`, `cr.commit`, vistas, seguridad y tests.
4. **Ruta del perfil**: `profile.env` declara `PROFILE_NORM_REPO` y `PROFILE_NORM_PATH`;
   el perfil no copia la norma, solo la referencia.
5. **Documentación**: las propuestas y decisiones de negocio viven en tech-doc; el kit
   documenta su propio uso, contratos y límites.

## Cómo se usa en una máquina

```bash
# 1. Clonar el repo de empresa con la credencial de Scalpers (SSH o HTTPS)
git clone git@github.com:ScalpersCompany/scalpers-tech-doc.git \
  ~/odoo-doodba-template/scalpers-tech-doc

# 2. Enlazar la norma canónica (una vez)
mkdir -p ~/.agents
ln -sfn ~/odoo-doodba-template/scalpers-tech-doc/AGENTS.md ~/.agents/AGENTS.md

# 3. Clonar el kit y los perfiles
git clone git@github.com:ScalpersCompany/dev-agent-kit.git ~/dev-agent-kit
git clone git@github.com:ScalpersCompany/dev-agent-profiles.git ~/dev-agent-profiles

# 4. Comprobar que la norma es la correcta y está limpia
bash ~/dev-agent-kit/scripts/check-techdoc.sh \
  --path ~/odoo-doodba-template/scalpers-tech-doc \
  --branch main --require-link
```

`check-techdoc.sh` comprueba el remoto, que existe `AGENTS.md`, la rama y el commit
opcionales, que el árbol no está sucio y que `~/.agents/AGENTS.md` apunta al fichero
correcto. No usa red, no hace fetch y no escribe en el repo de empresa.

## La regla de estado limpio

El check **falla cerrado** si tech-doc está sucio. Un `AGENTS.md` con cambios sin
commitear no es una norma reproducible: es el borrador de una persona. Para una revisión
local se puede usar `--allow-dirty`, pero no se debe instalar un perfil ni dar una entrega
por buena con la norma sucia.

## Qué no se hace

- **No se añade tech-doc como submódulo del kit.** Ataría el repo de empresa a los repos de
  herramientas, con dos credenciales y dos ciclos de vida; un clon del kit
  arrastraría la base documental. El workspace los mantiene hermanos y el check verifica
  la ruta.
- **No se copia `AGENTS.md` dentro del kit.** La copia se desincroniza y crea dos fuentes
  de verdad. Se enlaza y se comprueba.
- **No se copia la norma dentro del perfil.** El perfil solo añade reglas de Odoo.
- **No se empuja al repo de empresa desde el kit.** Los cambios de tech-doc siguen el
  proceso de la empresa y la autorización de Nico.
- **No se guarda un token de empresa en el kit.** El check es local y no hace red.

## CI y repo de empresa

El CI de los repos públicos no puede leer `ScalpersCompany/scalpers-tech-doc` sin una
credencial de empresa. No se mete un token en el kit. Si en el futuro se quiere una comprobación en CI,
se usa un deploy key o un token de solo lectura en los secrets del repositorio, nunca en
el árbol. Mientras no exista esa autorización, la comprobación es local y el CI del kit
solo valida su propio contrato.

## Estado actual en dev-nicolas

- El clon local está en `~/odoo-doodba-template/scalpers-tech-doc`.
- El remoto es `git@github.com:ScalpersCompany/scalpers-tech-doc.git`.
- La rama actual es `change/regla-version-manifest`, no `main`, y el árbol tiene cambios
  sin commitear en `AGENTS.md` y un fichero `--` sin seguimiento.
- Por tanto, el check **falla** hasta que ese trabajo se cierre en el repo de empresa. No
  se ha tocado, commiteado ni empujado tech-doc desde aquí.
- La URL de GitHub devuelve 404 sin autenticación porque el repo es privado; el clon local
  y el remoto SSH son la referencia.

## Actualizar la norma

1. Cerrar el cambio en tech-doc con su revisión y merge.
2. Actualizar el clon local (`git fetch` + `git switch main` + `git pull`).
3. Ejecutar `check-techdoc.sh` con `--branch main --require-link`.
4. Si se quiere fijar una versión, pasar `--commit <sha>` y anotar el SHA en la entrega.
5. No se actualiza el kit ni el perfil para cambiar la norma: se actualiza tech-doc.
