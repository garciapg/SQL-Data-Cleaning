-- The goal of this project is to successfully clean the Nashville Housing database,
-- and have it ready for future analysis.

Select *
From [SQL Project 1].dbo.NashvilleHousing;

-- 1. Standardizing Date Format

-- In this case, when uploading the dataset the SaleDate format was standardized automatically,
-- but in case that does not happen, let's update it anyways

Update NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate);

Select SaleDate from NashvilleHousing;

-------------------------------------------------------------------------------------------------------

-- 2. Populate Property Address Data

Select PropertyAddress
From NashvilleHousing
Where PropertyAddress IS NULL;

-- There are 32 rows without an Address
-- Let's see all the data

Select *
From NashvilleHousing
Where PropertyAddress IS NULL;

-- Since the ParcelID matches the Property Address, we'll update the null rows with the address of the
-- corresponding ParcelID

-- Let's see the rows with the same ParcelID but different IDs

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
From NashvilleHousing a
Join NashvilleHousing b
On a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID
Where a.PropertyAddress IS NULL;

-- Now we'll update the records to match the Property Address of the corresponding ParcelID

Update a
SET a.PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From NashvilleHousing a
Join NashvilleHousing b
On a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID
Where a.PropertyAddress IS NULL;

-- Now all the rows have the appropiate Address

-------------------------------------------------------------------------------------------------------

-- 3. Dividing PropertyAdress and OwnerAddress columns into Address, City, and State

-- PropertyAddres:

Select
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS City
From NashvilleHousing;

-- Let's create the columns for each new feature and add the data

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress Nvarchar(255);

Update NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress));

ALTER TABLE NashvilleHousing
ADD PropertySplitCity Nvarchar(255);

Update NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress));

-- Now let's remove the ',' at the end of PropertySplitAddress

Update NashvilleHousing
SET PropertySplitAddress = REPLACE(PropertySplitAddress, ',', '')

-- OwnerAddres:

Select
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
From NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);

ALTER TABLE NashvilleHousing
ADD OwnerSplitState Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

-------------------------------------------------------------------------------------------------------

-- 4. Change SoldAsVacant to Y and N

Select Distinct(SoldAsVacant), COUNT(SoldAsVacant)
From NashvilleHousing
Group By SoldAsVacant

-- Let's remove NULL

UPDATE NashvilleHousing
SET SoldAsVacant = 0
WHERE SoldAsVacant IS NULL;

-- Create a new table to store the strings

ALTER TABLE NashvilleHousing
ADD SoldAsVacantChar varchar(3);

UPDATE NashvilleHousing
SET SoldAsVacantChar = CASE 
                              WHEN SoldAsVacant = 1 THEN 'Yes'
                              WHEN SoldAsVacant = 0 THEN 'No'
                              ELSE NULL
                           END;

-------------------------------------------------------------------------------------------------------

-- 5. Remove Duplicates

-- First we look for the duplicates, if all the values of X columns are the same, and then we delete them

WITH RowNumCTE AS (
    Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
	             PropertyAddress,
	             SalePrice,
	             SaleDate,
	             LegalReference
	             ORDER BY
				    UniqueID
	                ) row_num
From NashvilleHousing
)
DELETE
From RowNumCTE
Where row_num > 1

-- let's check

WITH RowNumCTE AS (
    Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
	             PropertyAddress,
	             SalePrice,
	             SaleDate,
	             LegalReference
	             ORDER BY
				    UniqueID
	                ) row_num
From NashvilleHousing
)
Select *
From RowNumCTE
Where row_num > 1
Order By PropertyAddress

-- No more duplilcates

-------------------------------------------------------------------------------------------------------

-- 6. Delete Unused Columns


ALTER TABLE NashvilleHousing
DROP COLUMN PropertyAddress,
			OwnerAddress,
			SoldAsVacant,
			TaxDistrict

-------------------------------------------------------------------------------------------------------

Select *
From NashvilleHousing

-- Now the dataset is clean and ready for analysis!