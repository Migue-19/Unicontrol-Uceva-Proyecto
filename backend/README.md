# 🛠️ Backend UCEVA UniControl

Esta carpeta contiene la configuración necesaria para desplegar el backend y base de datos del proyecto **UniControl**. Toda la lógica de la base de datos se comunica con la API de Flutter.

## 🗃️ Archivos Principales

- `schema.sql`: Contiene **toda** la estructura de la base de datos (PostgreSQL), incluyendo roles, políticas de seguridad (Row-Level Security), Triggers y Funciones RPC requeridas para operar la plataforma.

## 🚀 Cómo Desplegar a Supabase

Para implementar esta base de datos a tu proyecto de Supabase:

1. Ve a tu proyecto en [Supabase Dashboard](https://supabase.com/dashboard/project/hncwcwbybkxqtmbgheqd/sql/new).
2. Entra al **SQL Editor**.
3. Haz click en "New Query".
4. Copia todo el contenido del archivo `schema.sql` y pégalo en el editor SQL.
5. Ejecuta el script completo (haz click en "RUN").

## ⚠️ NOTA: Seguridad y APIs
Todas las políticas de seguridad están programadas directamente en SQL a través de `ROW LEVEL SECURITY` y la capa postgREST (API generada instantáneamente por Supabase) procesará automáticamente los flujos que hemos implementado en la app de Flutter, como roles de `admin` o `estudiante`, inscripciones verificadas por RPC Functions (`inscribir_materia`, `confirmar_carga_academica`), etc.
