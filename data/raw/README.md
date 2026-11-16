# How to Download the Raw Dataset

The CSV files are **not** uploaded to GitHub because they are large. Download them yourself:

1. Go to **https://www.kaggle.com/datasets/patrickb1912/ipl-complete-dataset-20082020**
   (search Kaggle for "IPL Complete Dataset 2008-2024" if the link changes).
2. Sign in to Kaggle, or create a free account.
3. Click **Download**. You get a `.zip` file.
4. Extract the zip. Copy **`matches.csv`** and **`deliveries.csv`** into this folder (`data/raw/`).

The folder should then look like this:
```
data/raw/
├── README.md
├── matches.csv       (~1,095 rows, ~20 columns)
└── deliveries.csv    (~260,000 rows, ~17 columns)
```

**Backup option:** search Kaggle for "IPL dataset matches deliveries" and choose a dataset that has both files. The column names may differ slightly; the notebooks point out where.
