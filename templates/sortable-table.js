document.addEventListener('DOMContentLoaded', function() {
    const tables = document.querySelectorAll('table.sortable');

    tables.forEach(table => {
        const headers = table.querySelectorAll('thead th');
        const tbody = table.querySelector('tbody');
        let rowspansExpanded = false;

        // Expand all rowspan cells into individual cells
        function expandRowspans() {
            if (rowspansExpanded) return;

            const rows = Array.from(tbody.querySelectorAll('tr'));

            // Build a grid to track which cells span into which rows
            const grid = [];
            rows.forEach((row, rowIndex) => {
                grid[rowIndex] = grid[rowIndex] || [];
                let colIndex = 0;

                for (let cell of row.cells) {
                    // Find next available column
                    while (grid[rowIndex][colIndex]) {
                        colIndex++;
                    }

                    const rowSpan = cell.rowSpan || 1;
                    const colSpan = cell.colSpan || 1;

                    // Mark cells in grid and store reference
                    for (let r = 0; r < rowSpan; r++) {
                        grid[rowIndex + r] = grid[rowIndex + r] || [];
                        for (let c = 0; c < colSpan; c++) {
                            grid[rowIndex + r][colIndex + c] = {
                                cell: cell,
                                isOrigin: (r === 0 && c === 0)
                            };
                        }
                    }

                    colIndex += colSpan;
                }
            });

            // Now rebuild each row with expanded cells
            rows.forEach((row, rowIndex) => {
                const newCells = [];
                const gridRow = grid[rowIndex] || [];

                for (let colIndex = 0; colIndex < gridRow.length; colIndex++) {
                    const cellInfo = gridRow[colIndex];
                    if (cellInfo) {
                        if (cellInfo.isOrigin) {
                            // This is the original cell - remove rowspan
                            cellInfo.cell.rowSpan = 1;
                            newCells.push(cellInfo.cell);
                        } else {
                            // This cell spans from a previous row - create a copy
                            const clone = cellInfo.cell.cloneNode(true);
                            clone.rowSpan = 1;
                            newCells.push(clone);
                        }
                    }
                }

                // Clear row and add new cells
                while (row.firstChild) {
                    row.removeChild(row.firstChild);
                }
                newCells.forEach(cell => row.appendChild(cell));
            });

            rowspansExpanded = true;
        }

        headers.forEach((header, colIndex) => {
            header.classList.add('sortable');
            header.addEventListener('click', () => {
                // Expand rowspans on first sort
                expandRowspans();

                const rows = Array.from(tbody.querySelectorAll('tr'));
                const isAscending = header.classList.contains('sorted-asc');

                // Remove sorting classes from all headers
                headers.forEach(h => h.classList.remove('sorted-asc', 'sorted-desc'));

                // Add appropriate class to clicked header
                header.classList.add(isAscending ? 'sorted-desc' : 'sorted-asc');

                // Sort rows
                rows.sort((a, b) => {
                    const aCell = a.cells[colIndex];
                    const bCell = b.cells[colIndex];

                    if (!aCell || !bCell) return 0;

                    const aText = aCell.textContent.trim();
                    const bText = bCell.textContent.trim();

                    // Handle empty values
                    if (aText === '' && bText === '') return 0;
                    if (aText === '') return 1;  // Empty values go to the end
                    if (bText === '') return -1;

                    // Try to parse as number (single number only, not comma-separated lists)
                    const aNum = parseFloat(aText.replace(',', '.'));
                    const bNum = parseFloat(bText.replace(',', '.'));

                    let comparison = 0;
                    // Both must be valid numbers AND the original text should look numeric
                    if (!isNaN(aNum) && !isNaN(bNum) && /^-?\d+([.,]\d+)?$/.test(aText) && /^-?\d+([.,]\d+)?$/.test(bText)) {
                        comparison = aNum - bNum;
                    } else {
                        comparison = aText.localeCompare(bText, 'de');
                    }

                    return isAscending ? -comparison : comparison;
                });

                // Re-append sorted rows
                rows.forEach(row => tbody.appendChild(row));
            });
        });
    });
});