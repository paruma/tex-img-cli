# teximg

LaTeXの数式から透過PNG画像を生成するコマンドラインツールです。

## 概要

`teximg.sh` は、LaTeX形式で書かれた数式を引数として受け取り、背景が透明なPNG画像を生成します。画像のサイズは、基準のフォントサイズに対するパーセンテージで指定できます。

## 動作要件

このスクリプトを実行するには、以下のツールがシステムにインストールされている必要があります。

*   **pdflatex**: TeXのディストリビューションに含まれています。（例: TeX Live）
*   **ImageMagick**: PDFをPNGに変換するために使用します。
*   **bc**: スケール計算のために使用する計算ツールです。

*   **getopt**: コマンドラインオプションを解析するために使用します。（`util-linux` パッケージに含まれています）

Debian/Ubuntu系のシステムでは、以下のコマンドでインストールできます。

```bash
sudo apt-get update
sudo apt-get install texlive-latex-base imagemagick bc util-linux
```

## インストールと設定

1.  `teximg.sh` をダウンロードし、実行権限を付与します。

    ```bash
    chmod +x teximg.sh
    ```

2.  パスの通ったディレクトリ（例: `/usr/local/bin`）に配置すると、どこからでも `teximg.sh` のようにコマンド名だけで実行できます。

### ImageMagickのセキュリティポリシー設定

多くのLinuxディストリビューションでは、セキュリティ上の理由から、ImageMagickがPDFファイルを処理することがデフォルトで無効になっています。

この設定のままスクリプトを実行すると、`attempt to perform an operation not allowed by the security policy 'PDF'` のようなエラーが発生します。

この問題を解決するには、以下の手順でポリシーファイルを編集してください。

1.  管理者権限で `policy.xml` ファイルを開きます。パスは環境によって若干異なる場合があります。

    ```bash
    # Debian/Ubuntuの場合
    sudo nano /etc/ImageMagick-6/policy.xml
    ```

2.  ファイル内で `PDF` に関する行を探します。通常、以下のようになっています。

    ```xml
    <policy domain="coder" rights="none" pattern="PDF" />
    ```

3.  この行の `rights="none"` の部分を `rights="read|write"` に変更します。

    **変更後:**
    ```xml
    <policy domain="coder" rights="read|write" pattern="PDF" />
    ```

4.  ファイルを保存してエディタを終了します。これで、ImageMagickがPDFを扱えるようになります。

## 使い方

```
Usage: ./teximg.sh [options] <formula>

Generates a transparent PNG image from a LaTeX formula.

Options:
      --output FILE   Set the output file name (default: output.png)
      --thickness VAL Set thickness for dilating the font (e.g., 1.0). Default: 0.
      --scale VAL     Set the scaling percentage (default: 100).
      --help          Display this help and exit

Arguments:
  formula             The LaTeX formula to render (e.g., '\frac{a}{b}')
```

## スケール基準について

スケール(%)は、出力される画像の高さを基準にしています。`100%` を指定すると、画像の高さが **480ピクセル** になります。

- `100%` → 高さ 480px
- `50%` → 高さ 240px
- `10%` → 高さ 48px

幅は、数式の縦横比を維持して自動で調整されます。この基準値はスクリプト内の `BASELINE_HEIGHT` 変数で変更可能です。

## 使用例

**例1：基本的な使い方（デフォルトスケール）**

```bash
./teximg.sh 'a^2 + b^2 = c^2'
```
`output.png` という名前で、デフォルトのスケール `100%`（高さ480px相当）の画像が生成されます。

**例2：スケールを指定して生成**

```bash
./teximg.sh --scale 25 '\int_{-\infty}^{\infty} e^{-x^2} dx = \sqrt{\pi}'
```
高さが 480px * 0.25 = 120px 相当の画像が生成されます。

**例3：線の太さを指定して生成**

```bash
./teximg.sh --thickness 1 '\sqrt{x^2+y^2}'
```
デフォルトの出力ファイル名 (`output.png`) とスケール (`100%`) で、線の太さが1増した画像が生成されます。
