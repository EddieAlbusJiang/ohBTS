import { QuickCommand, DisplayMode } from './Types';
import preferences from '@ohos.data.preferences';

/**
 * 快捷指令管理器
 */
export class CommandManager {
  private static instance: CommandManager;
  private static readonly PREF_NAME = 'bluetooth_remote_commands';
  
  private _commands: QuickCommand[] = [];
  private preferences: preferences.Preferences | null = null;
  
  // 回调
  private onCommandsChange?: () => void;
  
  private constructor() {}
  
  static getInstance(): CommandManager {
    if (!CommandManager.instance) {
      CommandManager.instance = new CommandManager();
    }
    return CommandManager.instance;
  }
  
  // Getter
  get commands(): QuickCommand[] {
    return this._commands;
  }
  
  setOnCommandsChange(callback: () => void) {
    this.onCommandsChange = callback;
  }
  
  /**
   * 初始化
   */
  async initialize(context: Context): Promise<void> {
    try {
      this.preferences = await preferences.getPreferences(context, CommandManager.PREF_NAME);
      await this.loadCommands();
    } catch (error) {
      console.error('CommandManager initialization failed:', error);
    }
  }
  
  /**
   * 加载指令
   */
  private async loadCommands(): Promise<void> {
    if (!this.preferences) {
      return;
    }
    
    try {
      const commandsStr = await this.preferences.get('commands', '[]') as string;
      this._commands = JSON.parse(commandsStr);
    } catch (error) {
      console.error('Load commands failed:', error);
      this._commands = [];
    }
  }
  
  /**
   * 保存指令
   */
  private async saveCommands(): Promise<void> {
    if (!this.preferences) {
      return;
    }
    
    try {
      await this.preferences.put('commands', JSON.stringify(this._commands));
      await this.preferences.flush();
    } catch (error) {
      console.error('Save commands failed:', error);
    }
  }
  
  /**
   * 添加指令
   */
  async addCommand(name: string, content: string, displayMode: DisplayMode): Promise<void> {
    const command: QuickCommand = {
      id: Date.now().toString(),
      name,
      content,
      displayMode
    };
    
    this._commands.push(command);
    await this.saveCommands();
    
    if (this.onCommandsChange) {
      this.onCommandsChange();
    }
  }
  
  /**
   * 更新指令
   */
  async updateCommand(id: string, name: string, content: string, displayMode: DisplayMode): Promise<void> {
    const index = this._commands.findIndex(cmd => cmd.id === id);
    if (index !== -1) {
      this._commands[index] = {
        id,
        name,
        content,
        displayMode
      };
      
      await this.saveCommands();
      
      if (this.onCommandsChange) {
        this.onCommandsChange();
      }
    }
  }
  
  /**
   * 删除指令
   */
  async deleteCommand(id: string): Promise<void> {
    this._commands = this._commands.filter(cmd => cmd.id !== id);
    await this.saveCommands();
    
    if (this.onCommandsChange) {
      this.onCommandsChange();
    }
  }
  
  /**
   * 获取指令
   */
  getCommand(id: string): QuickCommand | undefined {
    return this._commands.find(cmd => cmd.id === id);
  }
}
