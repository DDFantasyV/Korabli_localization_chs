import zipfile
import os


def create_zip():
    files_to_zip = [
        'gui/fonts/SourceHanSansCN_WN_Bold.ttf',
        'gui/fonts/SourceHanSansCN_WN_Medium.ttf',
        'texts/ru/LC_MESSAGES/global.mo',
        'change.log',
        'LICENSE',
        'locale_config.xml',
        'meta.xml'
    ]

    output_filename = 'MK_L10N_CHS.mkmod'

    with zipfile.ZipFile(output_filename, 'w', compression=zipfile.ZIP_STORED) as zipf:
        for file_path in files_to_zip:
            if os.path.exists(file_path):
                zipf.write(file_path, file_path)

    print("Completed!")


if __name__ == "__main__":
    create_zip()
