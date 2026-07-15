# 🔐 Autenticación con Huella Dactilar en Aplicación Móvil Flutter

## 📱 Descripción del proyecto

Este proyecto implementa un sistema de autenticación biométrica mediante **huella dactilar** como una opción adicional para el registro e inicio de sesión en una aplicación móvil desarrollada con **Flutter**.

La autenticación biométrica permite mejorar la experiencia del usuario ofreciendo un acceso más rápido y cómodo, sin eliminar los métodos tradicionales de autenticación mediante correo y contraseña.

El usuario puede:

- ✅ Registrarse mediante credenciales tradicionales.
- ✅ Activar opcionalmente el inicio de sesión mediante huella dactilar.
- ✅ Iniciar sesión utilizando autenticación biométrica.
- ✅ Mantener disponible el acceso convencional con usuario y contraseña.
- ✅ Habilitar o deshabilitar la autenticación biométrica desde la aplicación.

---

# 🎯 Objetivo

Implementar la autenticación mediante huella dactilar como un mecanismo complementario de seguridad, aprovechando las capacidades biométricas disponibles en dispositivos móviles actuales.

La finalidad es reducir el tiempo de acceso y mejorar la interacción usuario-aplicación, manteniendo los métodos tradicionales como alternativa.

---

# 🛠️ Tecnologías utilizadas

- **Flutter** - Desarrollo de aplicación móvil multiplataforma.
- **Dart** - Lenguaje de programación.
- **Firebase Authentication** - Gestión de usuarios y autenticación.
- **local_auth** - Integración con sensores biométricos del dispositivo.
- **flutter_secure_storage** - Almacenamiento seguro de información sensible.
- **shared_preferences** - Persistencia de configuración del usuario.
- **Provider** - Gestión del estado de autenticación.
- **Go Router** - Navegación entre pantallas.

---

# 🔒 Funcionamiento de la autenticación biométrica

El flujo implementado es el siguiente:

1. El usuario crea una cuenta utilizando correo y contraseña.
2. La aplicación verifica si el dispositivo soporta autenticación biométrica.
3. El usuario puede activar la opción de acceso mediante huella.
4. La aplicación almacena la configuración biométrica de forma segura.
5. En futuros accesos, el usuario puede autenticarse mediante su huella.
6. Si la autenticación es correcta, se permite el ingreso al sistema.

---

# 📂 Implementación principal

## Servicio biométrico

La clase `BiometricService` administra toda la lógica relacionada con la huella dactilar:

- Verificación de compatibilidad del dispositivo.
- Activación y desactivación de biometría.
- Almacenamiento seguro de credenciales.
- Validación de identidad mediante huella.

Ejemplo de verificación del dispositivo:

```dart
Future<bool> isDeviceSupported() async {
  try {
    final isSupported =
        await _auth.isDeviceSupported();

    final biometrics =
        await _auth.getAvailableBiometrics();

    return isSupported &&
        biometrics.isNotEmpty;

  } catch (e) {
    return false;
  }
}
```

Este método permite comprobar si el dispositivo posee soporte biométrico y si existe una huella registrada.

---

## Autenticación mediante huella

La validación biométrica se realiza mediante:

```dart
Future<bool> authenticate({
  required String reason
}) async {

  try {

    final authenticated =
        await _auth.authenticate(
          localizedReason: reason,
          biometricOnly: true,
          sensitiveTransaction: true,
        );

    return authenticated;

  } catch (e) {

    return false;

  }
}
```

Si la validación es exitosa, el usuario puede ingresar sin escribir nuevamente sus credenciales.

---

# 🖥️ Pantalla de inicio de sesión

La pantalla de login permite dos métodos de acceso:

### Método tradicional
- Correo institucional.
- Contraseña.

### Método biométrico
- Botón de huella dactilar.
- Validación mediante sensor del dispositivo.

Ejemplo del acceso biométrico:

```dart
Future<void> _handleBiometricLogin() async {

  final auth =
      context.read<AuthProvider>();

  final ok =
      await auth.loginWithBiometrics();

  if(ok){

    context.go('/home');

  }

}
```

---

# 🔐 Seguridad

Para proteger la información sensible:

- Las contraseñas no se almacenan directamente en preferencias simples.
- Se utiliza:

```dart
FlutterSecureStorage()
```

para guardar información protegida.

Además:

- La autenticación biométrica depende del hardware del dispositivo.
- La huella no reemplaza la autenticación tradicional.
- El usuario decide si desea activar esta opción.

---

# 📱 Capturas del funcionamiento

## Registro de usuario

Proceso inicial donde el usuario crea su cuenta.


## Activación biométrica

El usuario puede habilitar la autenticación mediante huella.


## Inicio de sesión biométrico

Permite ingresar rápidamente utilizando el sensor del dispositivo.


---

# 🚀 Instalación y ejecución

Clonar el repositorio:

```bash
git clone URL_DEL_REPOSITORIO
```

Ingresar al proyecto:

```bash
cd nombre_del_proyecto
```

Instalar dependencias:

```bash
flutter pub get
```

Ejecutar aplicación:

```bash
flutter run
```

---

# 📌 Requisitos

- Dispositivo Android con sensor biométrico.
- Huella registrada en la configuración del dispositivo.
- Flutter SDK instalado.
- Cuenta Firebase configurada.

---

# 👨‍💻 Autor

**Franco Rojas Luque**  
**Diane Coraima Cabana Otazu**  
Ingeniería de Sistemas


---

# 📄 Licencia

Proyecto académico desarrollado para la asignatura de **Interacción Humano Computador**.
