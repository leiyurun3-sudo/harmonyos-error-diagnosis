import {
  RawFileContentSource,
  RawTextDecoder
} from '../../main/ets/storage/static/RawResourceStore';

export class SyntheticRawFileContentSource implements RawFileContentSource {
  private availableName: string;

  constructor(availableName: string) {
    this.availableName = availableName;
  }

  getRawFileContent(resourceName: string): Promise<Uint8Array> {
    if (resourceName === this.availableName) {
      return Promise.resolve(new Uint8Array([1, 2, 3]));
    }
    return Promise.reject(new Error('Synthetic rawfile read failure'));
  }
}

export class SyntheticRawTextDecoder implements RawTextDecoder {
  private text: string;
  private fails: boolean;

  constructor(text: string, fails: boolean = false) {
    this.text = text;
    this.fails = fails;
  }

  decode(content: Uint8Array): string {
    if (this.fails || content.length === 0) {
      throw new Error('Synthetic UTF-8 decode failure');
    }
    return this.text;
  }
}
