import { DIAGNOSIS_INPUT_MAX_CHARACTERS } from '../../constants/AppLimits';
import { SourceType } from '../../model/DiagnosisModels';
import { AppStateStore } from '../../store/AppStateStore';
import { getThemePalette, ThemePalette } from '../../theme/ThemeModels';
import { InlineErrorNotice } from '../common/InlineErrorNotice';

export type DiagnosisTextChanged = (text: string) => void;
export type DiagnosisEditorAction = () => void;

/** Controlled multi-line editor. Validation, sessions and diagnosis stay in the parent ViewModel. */
@Component
export struct DiagnosisTextEditor {
  @Consume('appState')
  appState: AppStateStore;
  @Prop
  text: string = '';
  @Prop
  sourceType: SourceType = SourceType.TEXT;
  @Prop
  characterCount: number = 0;
  @Prop
  maxCharacters: number = DIAGNOSIS_INPUT_MAX_CHARACTERS;
  @Prop
  errorMessage: string = '';
  @Prop
  readOnly: boolean = false;
  onTextChange?: DiagnosisTextChanged;
  onClear?: DiagnosisEditorAction;

  private palette(): ThemePalette {
    return getThemePalette(this.appState.effectiveTheme, this.appState.accentTheme);
  }

  build() {
    Column({ space: 12 }) {
      Row() {
        Text(this.sourceType === SourceType.IMAGE ?
          $r('app.string.diagnosis_source_image') : $r('app.string.diagnosis_source_text'))
          .fontSize(14 * this.appState.contentFontMultiplier)
          .fontColor(this.palette().secondaryText)
        Blank()
        Text(`${this.characterCount} / ${this.maxCharacters}`)
          .fontSize(14 * this.appState.contentFontMultiplier)
          .fontColor(this.characterCount > this.maxCharacters ? this.palette().error : this.palette().secondaryText)
          .accessibilityText(`${this.characterCount} / ${this.maxCharacters}`)
      }
      .width('100%')

      TextArea({
        text: this.text,
        placeholder: $r('app.string.diagnosis_editor_placeholder')
      })
        .id('diagnosis_text_editor')
        .width('100%')
        .height(280)
          .fontSize(16 * this.appState.contentFontMultiplier)
        .fontColor(this.palette().primaryText)
        .placeholderColor(this.palette().secondaryText)
        .backgroundColor(this.palette().surfaceBackground)
        .border({ width: 1, color: this.errorMessage.length > 0 ? this.palette().error : this.palette().accent })
        .borderRadius(12)
        .padding(14)
        .enabled(!this.readOnly)
        .onChange((value: string): void => {
          this.onTextChange?.(value);
        })

      Row() {
        Text($r('app.string.diagnosis_editor_privacy'))
          .layoutWeight(1)
          .fontSize(13 * this.appState.contentFontMultiplier)
          .fontColor(this.palette().secondaryText)
        Button($r('app.string.diagnosis_clear'))
          .enabled(!this.readOnly && this.text.length > 0)
          .constraintSize({ minHeight: 44 })
          .fontColor(!this.readOnly && this.text.length > 0 ? '#FFFFFFFF' : '#5B6474')
          .backgroundColor(!this.readOnly && this.text.length > 0 ? '#B42318' : '#D7DCE5')
          .onClick((): void => {
            this.onClear?.();
          })
      }
      .width('100%')

      if (this.errorMessage.length > 0) {
        InlineErrorNotice({ message: this.errorMessage })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
