# .NET 10 Upgrade Plan

## Upgrade Options

| Option | Selected | Why |
|---|---|---|
| Upgrade Strategy | All-at-Once | Single-project ASP.NET Framework web app requires coordinated project, MVC, configuration, and EF Core migration. |
| Project Approach | In-place modernization | User requested migration of this project and accepted defaults. |
| Test Coverage | Skip generation | No existing test project was found. |

## Strategy
**Selected**: All-at-Once

The migration updates the only project atomically because project format, hosting, MVC APIs, EF Core, routing, and static assets are interdependent.

### 01-project-and-hosting: Convert project and ASP.NET Core host

Convert ContosoUniversity.csproj from legacy ASP.NET Web Application format with packages.config to SDK-style Microsoft.NET.Sdk.Web targeting net10.0. Replace Global.asax, App_Start registration, System.Web hosting, Web.config runtime settings, and IIS-era startup with ASP.NET Core Program.cs, appsettings.json, endpoint routing, MVC services, and static files.

**Done when**: The project is SDK-style, targets net10.0, has an ASP.NET Core Program.cs host, no longer depends on System.Web MVC/WebPages/Optimization packages, and restore succeeds.

### 02-mvc-controllers-and-views: Migrate MVC surface to ASP.NET Core MVC

Migrate Controllers and Views from ASP.NET MVC 5 namespaces and helper APIs to ASP.NET Core MVC equivalents while preserving routes, action results, validation, anti-forgery behavior, view rendering, upload behavior, and user-facing pages.

**Done when**: Controllers and Razor views compile on ASP.NET Core MVC and conventional routing preserves existing URL patterns.

### 03-data-access-efcore: Upgrade EF Core and data configuration

Update EF Core 3.1.32 and related Microsoft.Extensions packages to the latest .NET 10-compatible package line, convert packages.config references to PackageReference, and adapt SchoolContext registration/configuration for ASP.NET Core dependency injection while preserving entity models and seed data.

**Done when**: EF Core packages are compatible with net10.0, SchoolContext is registered via DI, seed data remains available, and data-dependent controllers compile.

### 04-validation-and-cleanup: Validate build/tests and remove obsolete assets

Run restore, build, and available tests; fix all errors and warnings in modified projects. Remove obsolete ASP.NET Framework-only files/references while retaining content/static assets needed by the ASP.NET Core app.

**Done when**: dotnet restore and dotnet build complete successfully for ContosoUniversity.sln with zero warnings/errors, and test execution is reported.
