// Workspace - Gestión de proyectos y configuración .portulrc

class WorkspaceConfig {
  constructor(projectPath) {
    this.projectPath = projectPath;
    this.config = {};
  }

  loadConfig() {
    // TODO: Cargar .portulrc
  }

  saveConfig() {
    // TODO: Guardar configuración del proyecto
  }
}

module.exports = WorkspaceConfig;
