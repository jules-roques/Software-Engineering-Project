package fr.ensimag.deca.tree;


import fr.ensimag.ima.pseudocode.BinaryInstructionDValToReg;
import fr.ensimag.ima.pseudocode.DVal;
import fr.ensimag.ima.pseudocode.GPRegister;
import fr.ensimag.ima.pseudocode.instructions.MUL;

/**
 * @author gl44
 * @date 01/01/2024
 */
public class Multiply extends AbstractOpArith {

    public Multiply(AbstractExpr leftOperand, AbstractExpr rightOperand) {
        super(leftOperand, rightOperand);
    }


    @Override
    protected String getOperatorName() {
        return "*";
    }

    @Override
    public BinaryInstructionDValToReg getInstruction(DVal op1, GPRegister op2) {
        return new MUL(op1, op2);
    }

}
